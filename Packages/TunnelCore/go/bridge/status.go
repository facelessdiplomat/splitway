package main

/*
#cgo CFLAGS: -I${SRCDIR}/../../CInterface
#include "TunnelCoreTypes.h"
*/
import "C"

import (
	"errors"

	"splitway/tunnelcore/fdtunnel"
)

type tunnelStatus int32

const (
	statusOK                         tunnelStatus = C.TCStatusOK
	statusInvalidArgument            tunnelStatus = C.TCStatusInvalidArgument
	statusUnknownHandle              tunnelStatus = C.TCStatusUnknownHandle
	statusTunnelInterfaceUnavailable tunnelStatus = C.TCStatusTunnelInterfaceUnavailable
	statusConfigurationRejected      tunnelStatus = C.TCStatusConfigurationRejected
	statusDeviceUnavailable          tunnelStatus = C.TCStatusDeviceUnavailable
	statusInternalFailure            tunnelStatus = C.TCStatusInternalFailure
)

func statusOf(err error) tunnelStatus {
	switch {
	case err == nil:
		return statusOK
	case errors.Is(err, fdtunnel.ErrTunnelInterfaceUnavailable):
		return statusTunnelInterfaceUnavailable
	case errors.Is(err, fdtunnel.ErrConfigurationRejected):
		return statusConfigurationRejected
	case errors.Is(err, fdtunnel.ErrDeviceUnavailable):
		return statusDeviceUnavailable
	default:
		return statusInternalFailure
	}
}
