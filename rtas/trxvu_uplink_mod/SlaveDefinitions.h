/*
 * SlaveDefinitions.h
 *
 * Authors: Johan Sjöblom & John Wikman
 *
 * Description:
 *
 * - I2C_BIT_RATE: Determines the bit rate of the I2C bus in Hz.
 * - I2C_BUFFER_SIZE: The size of the TX and RX bufferinos for the slave.
 * - I2C_SLAVE_ADDRESS: The I2C address of the slave. Must be strictly smaller than 0x80.
 */

#ifndef SLAVEDEFINITIONS_H
#define SLAVEDEFINITIONS_H

#define I2C_BIT_RATE 400000L
#define I2C_BUFFER_SIZE 512

#define I2C_MASTER_ADDRESS 0x01

#define I2C_SLAVE_RECV_ADDR (I2C_SLAVE_ADDRESS << 1)
#define I2C_SLAVE_SEND_ADDR ((I2C_SLAVE_ADDRESS << 1) | 0x01)

#define I2C_SLAVE_ADDRESS 0x08

/* Standard commands sent by both master and slave */
#define MSP_NULL              0x00
#define MSP_DATA              0x01
/* OBC Requests (0 bytes data) */
#define MSP_OBC_REQ_PAYLOAD   0x10
#define MSP_OBC_REQ_HK        0x11
#define MSP_OBC_REQ_PUS       0x12
/* EXP Transmissions */
#define MSP_EXP_SEND_PAYLOAD  0x20
#define MSP_EXP_SEND_HK       0x21
#define MSP_EXP_SEND_PUS      0x22
/* OBC Transmissions */
#define MSP_OBC_SEND_TIME     0x30
#define MSP_OBC_SEND_ATTITUDE 0x31
#define MSP_OBC_SEND_PUS      0x32
/* OBC Control Commands (0 bytes data) */
#define MSP_OBC_ACTIVE        0xF0
#define MSP_OBC_SLEEP         0xF1
#define MSP_OBC_POWER_OFF     0xF2

/*
	macros for retrieving values from telecommands
*/
#define PACKET_ID(packet) (uint16_t) (packet[0]<<8 | packet[1])
#define PACKET_APID(packet) (uint16_t) (packet[0]&7<<8 | packet[1])
#define PACKET_LENGTH(packet) (uint16_t) (packet[4]<<8 | packet[5])+1
#define PACKET_SEQUENCE_COUNT(packet) (uint16_t) (packet[2]&3F<<8 | packet[3])
#define PACKET_SEQUENCE_CONTROL(packet) (uint16_t) (packet[2]<<8 | packet[3])
#define PACKET_SERVICE_TYPE(packet) packet[7]
#define PACKET_SERVICE_SUBTYPE(packet) packet[8]
#define TC_ACK(packet) packet[6]&0xF
#define TC_DATA(packet) packet+10
#define TC_DATA_LENGTH(packet) (uint16_t) (packet[4]<<8 | packet[5])-6

#endif
