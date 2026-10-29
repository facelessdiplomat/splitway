package main

import (
	"golang.zx2c4.com/wireguard/device"
	"splitway/tunnelcore/fdtunnel"
	"splitway/tunnelcore/logbridge"
)

type tunnelStarter func(logger *device.Logger) (*fdtunnel.Tunnel, error)

var runningTunnels = newTunnelRegistry()

func startTunnel(start tunnelStarter) (int32, tunnelStatus) {
	tunnel, err := start(logbridge.DeviceLogger(forwardLog))
	if err != nil {
		return 0, statusOf(err)
	}
	return runningTunnels.add(tunnel), statusOK
}

func updateTunnelConfiguration(handle int32, configuration string) tunnelStatus {
	tunnel, found := runningTunnels.tunnel(handle)
	if !found {
		return statusUnknownHandle
	}
	return statusOf(tunnel.Apply(configuration))
}

func tunnelConfiguration(handle int32) (string, tunnelStatus) {
	tunnel, found := runningTunnels.tunnel(handle)
	if !found {
		return "", statusUnknownHandle
	}
	configuration, err := tunnel.Configuration()
	if err != nil {
		return "", statusInternalFailure
	}
	return configuration, statusOK
}

func bumpTunnelSockets(handle int32) tunnelStatus {
	tunnel, found := runningTunnels.tunnel(handle)
	if !found {
		return statusUnknownHandle
	}
	if err := tunnel.BumpSockets(); err != nil {
		return statusDeviceUnavailable
	}
	return statusOK
}

func stopTunnel(handle int32) tunnelStatus {
	tunnel, found := runningTunnels.remove(handle)
	if !found {
		return statusUnknownHandle
	}
	tunnel.Stop()
	return statusOK
}
