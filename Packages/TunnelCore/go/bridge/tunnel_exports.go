package main

/*
#cgo CFLAGS: -I${SRCDIR}/../../CInterface
#include "TunnelCoreTypes.h"
*/
import "C"

import (
	"unsafe"

	"golang.zx2c4.com/wireguard/device"
	"splitway/tunnelcore/fdtunnel"
)

//export tc_fd_tunnel_start
func tc_fd_tunnel_start(tunnelFileDescriptor C.int32_t, configuration *C.char, handle *C.int32_t) C.TCStatus {
	if configuration == nil || handle == nil {
		return C.TCStatus(statusInvalidArgument)
	}
	goConfiguration := C.GoString(configuration)
	return C.TCStatus(guarded(func() tunnelStatus {
		newHandle, status := startTunnel(func(logger *device.Logger) (runningDevice, error) {
			return fdtunnel.StartOnFileDescriptor(int(tunnelFileDescriptor), goConfiguration, logger)
		})
		if status == statusOK {
			*handle = C.int32_t(newHandle)
		}
		return status
	}))
}

//export tc_fd_tunnel_set_service_routing
func tc_fd_tunnel_set_service_routing(handle C.int32_t, plan *C.char) C.TCStatus {
	if plan == nil {
		return C.TCStatus(statusInvalidArgument)
	}
	goPlan := C.GoString(plan)
	return C.TCStatus(guarded(func() tunnelStatus { return setServiceRouting(int32(handle), goPlan) }))
}

//export tc_tunnel_update_config
func tc_tunnel_update_config(handle C.int32_t, configuration *C.char) C.TCStatus {
	if configuration == nil {
		return C.TCStatus(statusInvalidArgument)
	}
	goConfiguration := C.GoString(configuration)
	return C.TCStatus(guarded(func() tunnelStatus { return updateTunnelConfiguration(int32(handle), goConfiguration) }))
}

//export tc_tunnel_get_config
func tc_tunnel_get_config(handle C.int32_t, configuration **C.char) C.TCStatus {
	if configuration == nil {
		return C.TCStatus(statusInvalidArgument)
	}
	return C.TCStatus(guarded(func() tunnelStatus {
		text, status := tunnelConfiguration(int32(handle))
		if status == statusOK {
			*configuration = C.CString(text)
		}
		return status
	}))
}

//export tc_tunnel_bump_sockets
func tc_tunnel_bump_sockets(handle C.int32_t) C.TCStatus {
	return C.TCStatus(guarded(func() tunnelStatus { return bumpTunnelSockets(int32(handle)) }))
}

//export tc_tunnel_stop
func tc_tunnel_stop(handle C.int32_t) C.TCStatus {
	return C.TCStatus(guarded(func() tunnelStatus { return stopTunnel(int32(handle)) }))
}

//export tc_set_log_callback
func tc_set_log_callback(callback C.TCLogCallback, context unsafe.Pointer) {
	routeLogs(callback, context)
}
