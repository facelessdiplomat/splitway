package main

import (
	"golang.zx2c4.com/wireguard/device"
	"splitway/tunnelcore/logbridge"
)

type runningDevice interface {
	Apply(configuration string) error
	Configuration() (string, error)
	BumpSockets() error
	Stop()
}

type deviceStarter func(logger *device.Logger) (runningDevice, error)

var runningDevices = newHandleTable[runningDevice]()

func startTunnel(start deviceStarter) (int32, tunnelStatus) {
	return startDevice(start, statusOf)
}

func startDevice(start deviceStarter, statusOfFailure func(error) tunnelStatus) (int32, tunnelStatus) {
	started, err := start(logbridge.DeviceLogger(forwardLog))
	if err != nil {
		return 0, statusOfFailure(err)
	}
	return runningDevices.add(started), statusOK
}

func updateTunnelConfiguration(handle int32, configuration string) tunnelStatus {
	running, found := runningDevices.value(handle)
	if !found {
		return statusUnknownHandle
	}
	return statusOf(running.Apply(configuration))
}

func tunnelConfiguration(handle int32) (string, tunnelStatus) {
	running, found := runningDevices.value(handle)
	if !found {
		return "", statusUnknownHandle
	}
	configuration, err := running.Configuration()
	if err != nil {
		return "", statusInternalFailure
	}
	return configuration, statusOK
}

func bumpTunnelSockets(handle int32) tunnelStatus {
	running, found := runningDevices.value(handle)
	if !found {
		return statusUnknownHandle
	}
	if err := running.BumpSockets(); err != nil {
		return statusDeviceUnavailable
	}
	return statusOK
}

func stopTunnel(handle int32) tunnelStatus {
	running, found := runningDevices.remove(handle)
	if !found {
		return statusUnknownHandle
	}
	running.Stop()
	return statusOK
}
