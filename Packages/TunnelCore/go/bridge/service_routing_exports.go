package main

/*
#cgo CFLAGS: -I${SRCDIR}/../../CInterface
#include "TunnelCoreTypes.h"
*/
import "C"

import (
	"net/netip"

	"golang.zx2c4.com/wireguard/device"
	"splitway/tunnelcore/fdtunnel"
	"splitway/tunnelcore/servicerouting"
)

//export tc_fd_tunnel_start_service_routing
func tc_fd_tunnel_start_service_routing(
	tunnelFileDescriptor C.int32_t,
	configuration *C.char,
	virtualDNS *C.char,
	fakeNetwork *C.char,
	upstreamDNS *C.char,
	handle *C.int32_t,
) C.TCStatus {
	if configuration == nil || virtualDNS == nil || fakeNetwork == nil || upstreamDNS == nil || handle == nil {
		return C.TCStatus(statusInvalidArgument)
	}
	plan, err := servicePlan(C.GoString(virtualDNS), C.GoString(fakeNetwork), C.GoString(upstreamDNS))
	if err != nil {
		return C.TCStatus(statusInvalidArgument)
	}
	goConfiguration := C.GoString(configuration)
	return C.TCStatus(guarded(func() tunnelStatus {
		newHandle, status := startTunnel(func(logger *device.Logger) (runningDevice, error) {
			return fdtunnel.StartOnFileDescriptorWithServiceRouting(int(tunnelFileDescriptor), goConfiguration, plan, logger)
		})
		if status == statusOK {
			*handle = C.int32_t(newHandle)
		}
		return status
	}))
}

func servicePlan(virtualDNS, fakeNetwork, upstreamDNS string) (servicerouting.Plan, error) {
	virtual, err := netip.ParseAddr(virtualDNS)
	if err != nil {
		return servicerouting.Plan{}, err
	}
	network, err := netip.ParsePrefix(fakeNetwork)
	if err != nil {
		return servicerouting.Plan{}, err
	}
	upstream, err := netip.ParseAddr(upstreamDNS)
	if err != nil {
		return servicerouting.Plan{}, err
	}
	return servicerouting.Plan{VirtualDNS: virtual, FakeNetwork: network, UpstreamDNS: upstream}, nil
}
