package main

import (
	"os"
	"strings"
	"testing"

	"go.uber.org/goleak"
	"golang.zx2c4.com/wireguard/device"
	"golang.zx2c4.com/wireguard/tun/tuntest"
	"splitway/tunnelcore/fdtunnel"
)

const (
	interfacePrivateKeyHex = "77076d0a7318a57d3c16c17251b26645df4c2f87ebc0992ab177fba51db92c2a"
	peerPublicKeyHex       = "de9edb7d7b7dc1b4d35b61c2ece435373f8343c85b78674dadfc7e146f882b4f"
	unknownHandle          = 4242
)

func TestMain(m *testing.M) {
	goleak.VerifyTestMain(m)
}

func TestStartedTunnelsReceiveDistinctPositiveHandles(t *testing.T) {
	first := startChannelTunnel(t)
	second := startChannelTunnel(t)
	defer stopTunnel(first)
	defer stopTunnel(second)

	if first <= 0 || second <= 0 || first == second {
		t.Fatalf("expected distinct positive handles, got %d and %d", first, second)
	}
}

func TestStoppingATunnelTwiceReportsAnUnknownHandle(t *testing.T) {
	handle := startChannelTunnel(t)

	if status := stopTunnel(handle); status != statusOK {
		t.Fatalf("first stop: expected success, got %d", status)
	}
	if status := stopTunnel(handle); status != statusUnknownHandle {
		t.Fatalf("second stop: expected an unknown handle, got %d", status)
	}
}

func TestOperationsOnAnUnknownHandleFail(t *testing.T) {
	if status := updateTunnelConfiguration(unknownHandle, "replace_peers=true\n"); status != statusUnknownHandle {
		t.Errorf("update: expected an unknown handle, got %d", status)
	}
	if _, status := tunnelConfiguration(unknownHandle); status != statusUnknownHandle {
		t.Errorf("configuration: expected an unknown handle, got %d", status)
	}
	if status := bumpTunnelSockets(unknownHandle); status != statusUnknownHandle {
		t.Errorf("bump: expected an unknown handle, got %d", status)
	}
	if status := setServiceRouting(unknownHandle, "{}"); status != statusUnknownHandle {
		t.Errorf("service routing: expected an unknown handle, got %d", status)
	}
	if status := stopTunnel(unknownHandle); status != statusUnknownHandle {
		t.Errorf("stop: expected an unknown handle, got %d", status)
	}
}

func TestRejectedConfigurationReturnsNoHandle(t *testing.T) {
	handle, status := startTunnel(onChannelDevice("private_key=zz\n"))

	if status != statusConfigurationRejected || handle != 0 {
		t.Fatalf("expected a rejected configuration without a handle, got %d and %d", status, handle)
	}
}

func TestUnavailableTunnelInterfaceIsReported(t *testing.T) {
	_, status := startTunnel(func(logger *device.Logger) (runningDevice, error) {
		return fdtunnel.StartOnFileDescriptor(-1, "private_key="+interfacePrivateKeyHex+"\n", logger)
	})

	if status != statusTunnelInterfaceUnavailable {
		t.Fatalf("expected an unavailable tunnel interface, got %d", status)
	}
}

func TestAppliesAndReadsBackTheConfiguration(t *testing.T) {
	handle := startChannelTunnel(t)
	defer stopTunnel(handle)
	peer := "replace_peers=true\npublic_key=" + peerPublicKeyHex + "\nreplace_allowed_ips=true\nallowed_ip=10.0.0.2/32\n"

	if status := updateTunnelConfiguration(handle, peer); status != statusOK {
		t.Fatalf("expected the update to succeed, got %d", status)
	}
	if status := updateTunnelConfiguration(handle, "public_key=zz\n"); status != statusConfigurationRejected {
		t.Fatalf("expected a malformed update to be rejected, got %d", status)
	}

	configuration, status := tunnelConfiguration(handle)
	if status != statusOK {
		t.Fatalf("expected the configuration, got %d", status)
	}
	if !strings.Contains(configuration, "public_key="+peerPublicKeyHex+"\n") {
		t.Fatalf("configuration lacks the applied peer")
	}
}

func TestRebindsTheSocketsOfARunningTunnel(t *testing.T) {
	handle := startChannelTunnel(t)
	defer stopTunnel(handle)

	if status := bumpTunnelSockets(handle); status != statusOK {
		t.Fatalf("expected the sockets to rebind, got %d", status)
	}
}

func TestRoutesServicesOfAFileDescriptorTunnel(t *testing.T) {
	handle := startChannelTunnel(t)
	defer stopTunnel(handle)

	status := setServiceRouting(handle, planFixture(t))

	if status != statusOK {
		t.Fatalf("expected the plan to apply, got %d", status)
	}
}

func TestRejectsAServiceRoutingPlanTheEngineCannotUse(t *testing.T) {
	handle := startChannelTunnel(t)
	defer stopTunnel(handle)
	cases := map[string]string{
		"unknown version": `{"version":99}`,
		"malformed":       `not a plan`,
		"invalid plan":    `{"version":1,"virtualResolver":"10.0.0.2","upstreamResolver":"1.1.1.1","fakeIPv4Network":"198.18.0.0/15"}`,
	}
	for name, document := range cases {
		t.Run(name, func(t *testing.T) {
			if status := setServiceRouting(handle, document); status != statusConfigurationRejected {
				t.Fatalf("expected a rejected plan, got %d", status)
			}
		})
	}
}

func startChannelTunnel(t *testing.T) int32 {
	t.Helper()
	handle, status := startTunnel(onChannelDevice("private_key=" + interfacePrivateKeyHex + "\nlisten_port=0\n"))
	if status != statusOK {
		t.Fatalf("expected the tunnel to start, got %d", status)
	}
	return handle
}

func onChannelDevice(configuration string) deviceStarter {
	return func(logger *device.Logger) (runningDevice, error) {
		return fdtunnel.Start(tuntest.NewChannelTUN().TUN(), configuration, logger)
	}
}

func planFixture(t *testing.T) string {
	t.Helper()
	document, err := os.ReadFile("../servicerouting/testdata/plan.json")
	if err != nil {
		t.Fatal(err)
	}
	return string(document)
}
