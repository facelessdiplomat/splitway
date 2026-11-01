package servicerouting

import (
	"sync"
	"sync/atomic"
	"time"

	"golang.zx2c4.com/wireguard/tun"
)

type TranslatingDevice struct {
	tun.Device
	router   atomic.Pointer[serviceRouter]
	applying sync.Mutex
}

func NewTranslatingDevice(device tun.Device) *TranslatingDevice {
	return &TranslatingDevice{Device: device}
}

func (device *TranslatingDevice) Apply(plan Plan) error {
	if err := plan.validate(); err != nil {
		return err
	}
	device.applying.Lock()
	defer device.applying.Unlock()
	if current := device.router.Load(); current != nil && current.plan == plan {
		return nil
	}
	device.router.Store(newServiceRouter(plan, time.Now))
	return nil
}

func (device *TranslatingDevice) Read(buffers [][]byte, sizes []int, offset int) (int, error) {
	count, err := device.Device.Read(buffers, sizes, offset)
	router := device.router.Load()
	if router == nil {
		return count, err
	}
	for index := range count {
		if !router.outbound(buffers[index][offset : offset+sizes[index]]) {
			sizes[index] = 0
		}
	}
	return count, err
}

func (device *TranslatingDevice) Write(buffers [][]byte, offset int) (int, error) {
	router := device.router.Load()
	if router == nil {
		return device.Device.Write(buffers, offset)
	}
	delivered := buffers[:0]
	for _, buffer := range buffers {
		replacement, isDelivered := router.inbound(buffer[offset:])
		if !isDelivered {
			continue
		}
		if replacement != nil {
			buffer = append(buffer[:offset], replacement...)
		}
		delivered = append(delivered, buffer)
	}
	if len(delivered) == 0 {
		return len(buffers), nil
	}
	if written, err := device.Device.Write(delivered, offset); err != nil {
		return written, err
	}
	return len(buffers), nil
}
