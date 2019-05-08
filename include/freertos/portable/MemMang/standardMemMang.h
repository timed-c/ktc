/*
 * standardMemMang.h
 *
 *  Created on: 18-Oct-2012
 *      Author: Akhil Piplani
 */

#ifndef STANDARDMEMMANG_H_
#define STANDARDMEMMANG_H_

void *pvPortMalloc( size_t xSize );
void vPortFree( void *pv );
void vPortInitialiseBlocks( void );
size_t xPortGetFreeHeapSize( void );

#endif /* STANDARDMEMMANG_H_ */
