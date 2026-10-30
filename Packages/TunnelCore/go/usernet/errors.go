package usernet

import "errors"

var (
	ErrInterfaceUnavailable = errors.New("userspace network interface unavailable")
	ErrNetworkStopped       = errors.New("userspace network stopped")
	ErrDialFailed           = errors.New("connection through the tunnel failed")
	ErrLookupFailed         = errors.New("name lookup through the tunnel failed")
	ErrEmptyReadBuffer      = errors.New("receiving needs a read buffer")
	ErrAlreadyReceiving     = errors.New("connection is already receiving")
)
