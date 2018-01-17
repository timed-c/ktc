/*
 * Author: Johan Sjöblom
 */

#ifndef DEBUG2_H
#define DEBUG2_H

#include <inttypes.h>

#ifdef __cplusplus
	#define EXTERNC extern "C"
#else
	#define EXTERNC
#endif

EXTERNC void debugSetup();
EXTERNC void writeDebug(char *msg);
EXTERNC void writeDebugInt(char *msg, int integer, int base);
EXTERNC void printDebugs();

#undef EXTERNC

void debugSetup();
void writeDebug(char *msg);
void writeDebugInt(char *msg, int integer, int base);
void printDebugs();

#endif
