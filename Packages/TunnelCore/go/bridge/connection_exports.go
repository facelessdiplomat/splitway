//go:build !ios

package main

/*
#cgo CFLAGS: -I${SRCDIR}/../../CInterface
#include "TunnelCoreTypes.h"
*/
import "C"

import "unsafe"

//export tc_connection_start_receiving
func tc_connection_start_receiving(connection C.int32_t, callbacks C.TCConnectionCallbacks, readByteCount C.int32_t, initialCredit C.int32_t) C.TCStatus {
	return C.TCStatus(guarded(func() tunnelStatus {
		if readByteCount <= 0 || callbacks.receive == nil || callbacks.finish == nil {
			return statusInvalidArgument
		}
		receiver, buffer := newCallbackReceiver(callbacks, int(readByteCount))
		status := startReceiving(int32(connection), receiver, buffer, int(initialCredit))
		if status != statusOK {
			receiver.release()
		}
		return status
	}))
}

//export tc_connection_write
func tc_connection_write(connection C.int32_t, bytes *C.uint8_t, length C.int32_t, writtenLength *C.int32_t) C.TCStatus {
	return C.TCStatus(guarded(func() tunnelStatus {
		if bytes == nil || length < 0 || writtenLength == nil {
			return statusInvalidArgument
		}
		written, status := writeToConnection(int32(connection), unsafe.Slice((*byte)(unsafe.Pointer(bytes)), int(length)))
		*writtenLength = C.int32_t(written)
		return status
	}))
}

//export tc_connection_grant
func tc_connection_grant(connection C.int32_t, byteCount C.int32_t) C.TCStatus {
	return C.TCStatus(guarded(func() tunnelStatus {
		if byteCount < 0 {
			return statusInvalidArgument
		}
		return grantCredit(int32(connection), int(byteCount))
	}))
}

//export tc_connection_close
func tc_connection_close(connection C.int32_t, closing C.TCConnectionClosing) C.TCStatus {
	return C.TCStatus(guarded(func() tunnelStatus {
		return closeConnection(int32(connection), connectionClosing(closing))
	}))
}
