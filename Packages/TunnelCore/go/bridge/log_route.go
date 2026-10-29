package main

/*
#cgo CFLAGS: -I${SRCDIR}/../../CInterface
#include <stdlib.h>
#include "TunnelCoreTypes.h"

static inline void tc_invoke_log_callback(TCLogCallback callback, void *context, TCLogLevel level, const char *message) {
	callback(context, level, message);
}
*/
import "C"

import (
	"sync/atomic"
	"unsafe"

	"splitway/tunnelcore/logbridge"
)

type logDestination struct {
	callback C.TCLogCallback
	context  unsafe.Pointer
}

var currentLogDestination atomic.Pointer[logDestination]

func routeLogs(callback C.TCLogCallback, context unsafe.Pointer) {
	if callback == nil {
		currentLogDestination.Store(nil)
		return
	}
	currentLogDestination.Store(&logDestination{callback: callback, context: context})
}

func forwardLog(level logbridge.Level, message string) {
	destination := currentLogDestination.Load()
	if destination == nil {
		return
	}
	cMessage := C.CString(message)
	defer C.free(unsafe.Pointer(cMessage))
	C.tc_invoke_log_callback(destination.callback, destination.context, C.TCLogLevel(level), cMessage)
}
