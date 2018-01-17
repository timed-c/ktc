/*
 * Author: Johan Sjöblom
 */

#include <string.h>
#include "I2Cslave.h"
#include "debug2.h"
#include "SlaveDefinitions.h"

// RX Buffer
static uint8_t rxBuffer[I2C_BUFFER_SIZE];
static uint8_t rxBufferIndex;
static uint8_t rxBufferLength;

// Service buffer
static uint8_t srvBuffer[I2C_BUFFER_SIZE];
static uint8_t srvBufferIndex;
static uint8_t srvBufferLength;

static volatile uint32_t I2C_transmitIndex;
  
static volatile uint8_t writeBuffer[I2C_BUFFER_SIZE];
MSP_packetInfo currentPacket = {
  .MSP_packet = writeBuffer,
  .packetSize = 0
};

// TWI instance
static Twi *twi = WIRE_INTERFACE;

// TWI state
typedef enum {
  UNINITIALIZED,
  READY,
  RECV,
  SEND
} I2C_Status;
static I2C_Status status;

// TWI clock frequency
static const uint32_t TWI_CLOCK = 100000;
static uint32_t twiClock;

void (*I2C_receiveCallback)(uint8_t*, uint32_t dataSize);
void (*I2C_transmitBeginCallback)(void);
void (*I2C_transmitCompleteCallback)(void);

static inline bool TWI_STATUS_SVREAD(uint32_t status) {
	return (status & TWI_SR_SVREAD) == TWI_SR_SVREAD;
}

static inline bool TWI_STATUS_SVACC(uint32_t status) {
	return (status & TWI_SR_SVACC) == TWI_SR_SVACC;
}

static inline bool TWI_STATUS_GACC(uint32_t status) {
	return (status & TWI_SR_GACC) == TWI_SR_GACC;
}

static inline bool TWI_STATUS_EOSACC(uint32_t status) {
	return (status & TWI_SR_EOSACC) == TWI_SR_EOSACC;
}

static inline bool TWI_STATUS_NACK(uint32_t status) {
	return (status & TWI_SR_NACK) == TWI_SR_NACK;
}

void ISRnStuffInit() {
  pmc_enable_periph_clk(WIRE_INTERFACE_ID);
  PIO_Configure(
      g_APinDescription[PIN_WIRE_SDA].pPort,
      g_APinDescription[PIN_WIRE_SDA].ulPinType,
      g_APinDescription[PIN_WIRE_SDA].ulPin,
      g_APinDescription[PIN_WIRE_SDA].ulPinConfiguration);
  PIO_Configure(
      g_APinDescription[PIN_WIRE_SCL].pPort,
      g_APinDescription[PIN_WIRE_SCL].ulPinType,
      g_APinDescription[PIN_WIRE_SCL].ulPin,
      g_APinDescription[PIN_WIRE_SCL].ulPinConfiguration);

  NVIC_DisableIRQ(WIRE_ISR_ID);
  NVIC_ClearPendingIRQ(WIRE_ISR_ID);
  NVIC_SetPriority(WIRE_ISR_ID, 0);
  NVIC_EnableIRQ(WIRE_ISR_ID);
}

void I2C_setup(
  void (*receiveCallback)(uint8_t* data, uint32_t dataSize), 
  void (*transmitBeginCallback)(void), 
  void (*transmitCompleteCallback)(void)) {
    ISRnStuffInit();

    I2C_receiveCallback = receiveCallback;
    I2C_transmitBeginCallback = transmitBeginCallback;
    I2C_transmitCompleteCallback = transmitCompleteCallback;

    // Disable PDC channel (no DMA as slave)
    twi->TWI_PTCR = UART_PTCR_RXTDIS | UART_PTCR_TXTDIS;

    TWI_ConfigureSlave(twi, I2C_SLAVE_ADDRESS);
    status = READY;
    TWI_EnableIt(twi, TWI_IER_SVACC);
}

int xyz = 0;
void onService(void) {
  /*
  xyz++;
  if (xyz > 25) {
    TWI_DisableIt(twi, TWI_IDR_SVACC | TWI_IDR_RXRDY | TWI_IDR_GACC | TWI_IDR_NACK
       | TWI_IDR_EOSACC | TWI_IDR_SCL_WS | TWI_IDR_TXCOMP);
    return;
  }*/
	// Retrieve interrupt status
	uint32_t sr = TWI_GetStatus(twi);
  /*
  char debug[32]; debug[0] = '\0';
  strcat(debug, "ISR: 0x");
  char val[10];
  itoa(sr,val,16);
  strcat(debug, val);
  writeDebug(debug);
  /*
  char debug2[32]; debug2[0] = '\0';
  strcat(debug2, "SCLWS: "); 
  char val2[10]; itoa((sr & TWI_SR_SCLWS), val2, 10);
  strcat(debug2, val2); */
  
	if (status == READY && TWI_STATUS_SVACC(sr)) {
		TWI_DisableIt(twi, TWI_IDR_SVACC);
		TWI_EnableIt(twi, TWI_IER_RXRDY | TWI_IER_GACC | TWI_IER_NACK
				| TWI_IER_EOSACC | TWI_IER_SCL_WS | TWI_IER_TXCOMP);
		srvBufferLength = 0;
		srvBufferIndex = 0;

		// Detect if we should go into RECV or SEND status
		// SVREAD==1 means *master* reading -> SLAVE_SEND
		if (!TWI_STATUS_SVREAD(sr)) {
			status = RECV;
		} else {
			status = SEND;
			// Alert calling program to generate a response ASAP
			I2C_transmitBeginCallback();
      I2C_transmitIndex = 0;
		}
	}

	if (status != READY && TWI_STATUS_EOSACC(sr)) {
		if (status == RECV) {
			//rxbuffer allows to receive another packet while the user program reads actual data
			for (uint8_t i = 0; i < srvBufferLength; ++i)
				rxBuffer[i] = srvBuffer[i];
			rxBufferIndex = 0;
			rxBufferLength = srvBufferLength;

			// Alert calling program
      I2C_receiveCallback(&rxBuffer, rxBufferLength); //currently no error support ~     
		} else {
      I2C_transmitCompleteCallback();
		}

		// Transfer completed
		TWI_EnableIt(twi, TWI_SR_SVACC);
		TWI_DisableIt(twi, TWI_IDR_RXRDY | TWI_IDR_GACC | TWI_IDR_NACK
				| TWI_IDR_EOSACC | TWI_IDR_SCL_WS | TWI_IER_TXCOMP);
		status = READY;
	}

	if (status == RECV) {
		if (TWI_STATUS_RXRDY(sr)) {
			if (srvBufferLength < I2C_BUFFER_SIZE) {
        srvBuffer[srvBufferLength] = TWI_ReadByte(twi);
        //debughexln("read byte", srvBuffer[srvBufferLength]);
        srvBufferLength++;
			}
		}
	}
 
	if (status == SEND) {
		if (TWI_STATUS_TXRDY(sr) && !TWI_STATUS_NACK(sr)) {
      if (I2C_transmitIndex < currentPacket.packetSize) {
        char buf[32]; buf[0] = '\0';
        strcat(buf, "Sending byte: 0x");
        itoa((currentPacket.MSP_packet)[I2C_transmitIndex], buf + strlen(buf), 16);
        if ((currentPacket.MSP_packet)[I2C_transmitIndex] != 0xab) {
          //writeDebug(buf); 
        }
        TWI_WriteByte(twi, (currentPacket.MSP_packet)[I2C_transmitIndex++]);
      } else {
        //writeDebug("Master asking for too much data, sending junk");
        TWI_WriteByte(twi, 0xFF);
      }
		}
	}
}

void WIRE_ISR_HANDLER(void) {
	onService();
}


/* -------- TWI_SR : (TWI Offset: 0x20) Status Register -------- *
#define TWI_SR_TXCOMP (0x1u << 0) /**< \brief (TWI_SR) Transmission Completed (automatically set / reset) *
#define TWI_SR_RXRDY (0x1u << 1) /**< \brief (TWI_SR) Receive Holding Register Ready (automatically set / reset) *
#define TWI_SR_TXRDY (0x1u << 2) /**< \brief (TWI_SR) Transmit Holding Register Ready (automatically set / reset) *
#define TWI_SR_SVREAD (0x1u << 3) /**< \brief (TWI_SR) Slave Read, indicates direction of transfer (automatically set / reset) *
#define TWI_SR_SVACC (0x1u << 4) /**< \brief (TWI_SR) Slave Access,-> we got addressed (automatically set / reset) *
#define TWI_SR_GACC (0x1u << 5) /**< \brief (TWI_SR) General Call Access (clear on read) *
#define TWI_SR_OVRE (0x1u << 6) /**< \brief (TWI_SR) Overrun Error (clear on read) *
#define TWI_SR_NACK (0x1u << 8) /**< \brief (TWI_SR) Not Acknowledged (clear on read) *
#define TWI_SR_ARBLST (0x1u << 9) /**< \brief (TWI_SR) Arbitration Lost (clear on read) *
#define TWI_SR_SCLWS (0x1u << 10) /**< \brief (TWI_SR) Clock Wait State (automatically set / reset) *
#define TWI_SR_EOSACC (0x1u << 11) /**< \brief (TWI_SR) End Of Slave Access,-> master generated STOP-condition (clear on read) *
#define TWI_SR_ENDRX (0x1u << 12) /**< \brief (TWI_SR) End of RX buffer *
#define TWI_SR_ENDTX (0x1u << 13) /**< \brief (TWI_SR) End of TX buffer *
#define TWI_SR_RXBUFF (0x1u << 14) /**< \brief (TWI_SR) RX Buffer Full *
#define TWI_SR_TXBUFE (0x1u << 15) /**< \brief (TWI_SR) TX Buffer Empty */
