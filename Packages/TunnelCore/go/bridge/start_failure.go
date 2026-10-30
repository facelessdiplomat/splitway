package main

import (
	"errors"

	"splitway/tunnelcore/fdtunnel"
)

const startFailurePrefix = "tunnel failed to start: "

func startFailureDescription(err error) string {
	if errors.Is(err, fdtunnel.ErrConfigurationRejected) {
		return startFailurePrefix + fdtunnel.ErrConfigurationRejected.Error()
	}
	return startFailurePrefix + err.Error()
}
