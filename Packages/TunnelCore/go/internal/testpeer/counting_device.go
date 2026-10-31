package testpeer

import (
	"sync/atomic"

	"golang.zx2c4.com/wireguard/tun"
)

type PacketCounts struct {
	Received uint64
	Sent     uint64
}

type countingDevice struct {
	tun.Device
	received atomic.Uint64
	sent     atomic.Uint64
}

func (device *countingDevice) Read(buffers [][]byte, sizes []int, offset int) (int, error) {
	count, err := device.Device.Read(buffers, sizes, offset)
	device.sent.Add(uint64(count))
	return count, err
}

func (device *countingDevice) Write(buffers [][]byte, offset int) (int, error) {
	count, err := device.Device.Write(buffers, offset)
	device.received.Add(uint64(count))
	return count, err
}

func (device *countingDevice) counts() PacketCounts {
	return PacketCounts{Received: device.received.Load(), Sent: device.sent.Load()}
}
