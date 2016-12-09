#ifdef __APPLE__
#define _ANSI_SOURCE
#define __AVAILABILITY__
#define __OSX_AVAILABLE_STARTING(_mac, _iphone)
#define __OSX_AVAILABLE_BUT_DEPRECATED(_macIntro, _macDep, _iphoneIntro, _iphoneDep)
#define __OSX_AVAILABLE_BUT_DEPRECATED_MSG(_osxIntro, _osxDep, _iosIntro, _iosDep, _msg)
#define __WATCHOS_PROHIBITED
#define __TVOS_PROHIBITED
#endif

#ifndef __AVAILABILITY__
#define __AVAILABILITY__
#endif


#include<stdio.h>

void main(){
	sdelay(5, "ms");
}
