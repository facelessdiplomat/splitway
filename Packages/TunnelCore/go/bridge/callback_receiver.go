//go:build !ios

package main

/*
#cgo CFLAGS: -I${SRCDIR}/../../CInterface
#include <stdlib.h>
#include "TunnelCoreTypes.h"

static inline void tc_invoke_receive(TCConnectionCallbacks callbacks, const uint8_t *bytes, int32_t length) {
	callbacks.receive(callbacks.context, bytes, length);
}

static inline void tc_invoke_finish(TCConnectionCallbacks callbacks, TCStatus status) {
	callbacks.finish(callbacks.context, status);
}
*/
import "C"

import "unsafe"

type callbackReceiver struct {
	callbacks C.TCConnectionCallbacks
	buffer    unsafe.Pointer
}

func newCallbackReceiver(callbacks C.TCConnectionCallbacks, byteCount int) (*callbackReceiver, []byte) {
	buffer := C.malloc(C.size_t(byteCount))
	return &callbackReceiver{callbacks: callbacks, buffer: buffer}, unsafe.Slice((*byte)(buffer), byteCount)
}

func (receiver *callbackReceiver) Receive(data []byte) {
	C.tc_invoke_receive(receiver.callbacks, (*C.uint8_t)(unsafe.Pointer(unsafe.SliceData(data))), C.int32_t(len(data)))
}

func (receiver *callbackReceiver) Finish(err error) {
	C.tc_invoke_finish(receiver.callbacks, C.TCStatus(finishingStatusOf(err)))
	receiver.release()
}

func (receiver *callbackReceiver) release() {
	C.free(receiver.buffer)
}

func finishingStatusOf(err error) tunnelStatus {
	if err == nil {
		return statusOK
	}
	return statusConnectionFailed
}
