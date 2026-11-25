//go:build !ios

package main

import "testing"

func TestRejectsServiceRoutingOnATunnelThatDoesNotRouteServices(t *testing.T) {
	handle := startChannelTunnel(t)
	defer stopTunnel(handle)

	if status := setServiceRouting(handle, planFixture(t)); status != statusInvalidArgument {
		t.Fatalf("expected an invalid argument, got %d", status)
	}
}
