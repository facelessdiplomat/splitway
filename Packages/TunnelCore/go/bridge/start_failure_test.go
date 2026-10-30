package main

import (
	"errors"
	"fmt"
	"strings"
	"testing"

	"splitway/tunnelcore/fdtunnel"
)

func TestDescribesAStartFailureWithItsCause(t *testing.T) {
	cause := errors.New("route ip+net: no such network interface")
	failure := fmt.Errorf("%w: %w", fdtunnel.ErrTunnelInterfaceUnavailable, cause)

	description := startFailureDescription(failure)

	if !strings.Contains(description, fdtunnel.ErrTunnelInterfaceUnavailable.Error()) ||
		!strings.Contains(description, cause.Error()) {
		t.Fatalf("expected the failure and its cause, got %q", description)
	}
}

func TestHidesTheDetailsOfARejectedConfiguration(t *testing.T) {
	cause := errors.New("failed to set private_key: " + interfacePrivateKeyHex)
	failure := fmt.Errorf("%w: %w", fdtunnel.ErrConfigurationRejected, cause)

	description := startFailureDescription(failure)

	if strings.Contains(description, interfacePrivateKeyHex) {
		t.Fatalf("the description shows configuration values: %q", description)
	}
	if !strings.Contains(description, fdtunnel.ErrConfigurationRejected.Error()) {
		t.Fatalf("expected the rejected configuration to be named, got %q", description)
	}
}
