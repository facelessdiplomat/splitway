package main

import (
	"context"
	"errors"

	"splitway/tunnelcore/usernet"
)

func userspaceStatusOf(err error) tunnelStatus {
	switch {
	case errors.Is(err, usernet.ErrInterfaceUnavailable):
		return statusTunnelInterfaceUnavailable
	case errors.Is(err, context.DeadlineExceeded):
		return statusTimedOut
	case errors.Is(err, usernet.ErrDialFailed):
		return statusConnectionFailed
	case errors.Is(err, usernet.ErrLookupFailed):
		return statusLookupFailed
	case errors.Is(err, usernet.ErrNetworkStopped):
		return statusNetworkStopped
	default:
		return statusOf(err)
	}
}
