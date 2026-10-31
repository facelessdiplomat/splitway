package servicerouting

import (
	"time"

	"golang.zx2c4.com/wireguard/tun"
)

type TranslatingDevice struct {
	tun.Device
	router *serviceRouter
}

func NewTranslatingDevice(device tun.Device, plan Plan) (*TranslatingDevice, error) {
	if err := plan.validate(); err != nil {
		return nil, err
	}
	return &TranslatingDevice{Device: device, router: newServiceRouter(plan, time.Now)}, nil
}

func (device *TranslatingDevice) Read(buffers [][]byte, sizes []int, offset int) (int, error) {
	count, err := device.Device.Read(buffers, sizes, offset)
	for index := range count {
		if !device.router.outbound(buffers[index][offset : offset+sizes[index]]) {
			sizes[index] = 0
		}
	}
	return count, err
}

func (device *TranslatingDevice) Write(buffers [][]byte, offset int) (int, error) {
	delivered := buffers[:0]
	for _, buffer := range buffers {
		replacement, isDelivered := device.router.inbound(buffer[offset:])
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
