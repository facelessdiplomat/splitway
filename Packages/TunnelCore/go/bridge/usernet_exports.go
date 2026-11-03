package main

/*
#cgo CFLAGS: -I${SRCDIR}/../../CInterface
#include "TunnelCoreTypes.h"
*/
import "C"

//export tc_usernet_start
func tc_usernet_start(configuration, addresses, dnsServers *C.char, mtu C.int32_t, handle *C.int32_t) C.TCStatus {
	return C.TCStatus(guarded(func() tunnelStatus {
		if configuration == nil || addresses == nil || dnsServers == nil || handle == nil {
			return statusInvalidArgument
		}
		newHandle, status := startUserspaceNetwork(
			C.GoString(configuration), C.GoString(addresses), C.GoString(dnsServers), int(mtu),
		)
		if status == statusOK {
			*handle = C.int32_t(newHandle)
		}
		return status
	}))
}

//export tc_usernet_dial_tcp
func tc_usernet_dial_tcp(network C.int32_t, address *C.char, port C.uint16_t, timeoutMilliseconds C.int32_t, connection *C.int32_t) C.TCStatus {
	return C.TCStatus(guarded(func() tunnelStatus {
		if address == nil || connection == nil {
			return statusInvalidArgument
		}
		newConnection, status := dialTCP(int32(network), C.GoString(address), uint16(port), int(timeoutMilliseconds))
		if status == statusOK {
			*connection = C.int32_t(newConnection)
		}
		return status
	}))
}

//export tc_usernet_dial_udp
func tc_usernet_dial_udp(network C.int32_t, address *C.char, port C.uint16_t, connection *C.int32_t) C.TCStatus {
	return C.TCStatus(guarded(func() tunnelStatus {
		if address == nil || connection == nil {
			return statusInvalidArgument
		}
		newConnection, status := dialUDP(int32(network), C.GoString(address), uint16(port))
		if status == statusOK {
			*connection = C.int32_t(newConnection)
		}
		return status
	}))
}

//export tc_usernet_lookup_host
func tc_usernet_lookup_host(network C.int32_t, name *C.char, timeoutMilliseconds C.int32_t, addresses **C.char) C.TCStatus {
	return C.TCStatus(guarded(func() tunnelStatus {
		if name == nil || addresses == nil {
			return statusInvalidArgument
		}
		text, status := lookupHost(int32(network), C.GoString(name), int(timeoutMilliseconds))
		if status == statusOK {
			*addresses = C.CString(text)
		}
		return status
	}))
}
