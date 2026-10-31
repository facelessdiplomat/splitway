package usernet

import (
	"os"
	"sync"
	"time"

	"golang.zx2c4.com/wireguard/tun"
)

const (
	acknowledgementHoldDuration   = time.Millisecond
	maximumAcknowledgementStretch = 32 * 1024
	coalescingReadBatchSize       = 32
)

type coalescingDevice struct {
	tun.Device
	packetByteCount int
	mutex           sync.Mutex
	coalescer       *acknowledgementCoalescer
	ready           [][]byte
	isClosed        bool
	isTimerArmed    bool
	timer           *time.Timer
	readable        chan struct{}
	pumpFinished    chan struct{}
}

func newCoalescingDevice(inner tun.Device) (*coalescingDevice, error) {
	packetByteCount, err := inner.MTU()
	if err != nil {
		return nil, err
	}
	device := &coalescingDevice{
		Device:          inner,
		packetByteCount: packetByteCount,
		coalescer:       newAcknowledgementCoalescer(acknowledgementHoldDuration, maximumAcknowledgementStretch),
		readable:        make(chan struct{}, 1),
		pumpFinished:    make(chan struct{}),
	}
	device.timer = time.AfterFunc(acknowledgementHoldDuration, device.releaseExpired)
	device.timer.Stop()
	go device.pump()
	return device, nil
}

func (device *coalescingDevice) Read(buffers [][]byte, sizes []int, offset int) (int, error) {
	for {
		device.mutex.Lock()
		if len(device.ready) > 0 {
			count := min(len(buffers), len(device.ready))
			for index := range count {
				sizes[index] = copy(buffers[index][offset:], device.ready[index])
			}
			device.ready = device.ready[count:]
			hasMore := len(device.ready) > 0
			device.mutex.Unlock()
			if hasMore {
				device.signalReadable()
			}
			return count, nil
		}
		if device.isClosed {
			device.mutex.Unlock()
			return 0, os.ErrClosed
		}
		device.mutex.Unlock()
		<-device.readable
	}
}

func (device *coalescingDevice) BatchSize() int {
	return coalescingReadBatchSize
}

func (device *coalescingDevice) Close() error {
	err := device.Device.Close()
	<-device.pumpFinished
	return err
}

func (device *coalescingDevice) pump() {
	defer close(device.pumpFinished)
	buffers, sizes := make([][]byte, 1), make([]int, 1)
	for {
		buffers[0] = make([]byte, device.packetByteCount)
		count, err := device.Device.Read(buffers, sizes, 0)
		if err != nil {
			device.finish()
			return
		}
		if count > 0 {
			device.accept(buffers[0][:sizes[0]])
		}
	}
}

func (device *coalescingDevice) accept(packet []byte) {
	device.mutex.Lock()
	defer device.mutex.Unlock()
	device.publishLocked(device.coalescer.accept(packet, time.Now()))
	device.armTimerLocked()
}

func (device *coalescingDevice) releaseExpired() {
	device.mutex.Lock()
	defer device.mutex.Unlock()
	device.isTimerArmed = false
	device.publishLocked(device.coalescer.expire(time.Now()))
	device.armTimerLocked()
}

func (device *coalescingDevice) finish() {
	device.mutex.Lock()
	device.coalescer.drain()
	device.isClosed = true
	device.timer.Stop()
	device.mutex.Unlock()
	device.signalReadable()
}

func (device *coalescingDevice) publishLocked(packets [][]byte) {
	if len(packets) == 0 {
		return
	}
	device.ready = append(device.ready, packets...)
	device.signalReadable()
}

func (device *coalescingDevice) armTimerLocked() {
	if device.isTimerArmed || device.isClosed {
		return
	}
	deadline, isHolding := device.coalescer.nextDeadline()
	if !isHolding {
		return
	}
	device.isTimerArmed = true
	device.timer.Reset(time.Until(deadline))
}

func (device *coalescingDevice) signalReadable() {
	select {
	case device.readable <- struct{}{}:
	default:
	}
}
