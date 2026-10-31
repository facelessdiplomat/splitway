package servicerouting

import "golang.zx2c4.com/wireguard/tun"

type TranslatingDevice struct {
	tun.Device
	translator *translator
}

func NewTranslatingDevice(inner tun.Device, plan Plan) *TranslatingDevice {
	return &TranslatingDevice{Device: inner, translator: newTranslator(plan)}
}

func (device *TranslatingDevice) Read(buffers [][]byte, sizes []int, offset int) (int, error) {
	count, err := device.Device.Read(buffers, sizes, offset)
	for index := range count {
		if !device.translator.outbound(buffers[index][offset : offset+sizes[index]]) {
			sizes[index] = 0
		}
	}
	return count, err
}

func (device *TranslatingDevice) Write(buffers [][]byte, offset int) (int, error) {
	for index, buffer := range buffers {
		if translated, isReplaced := device.translator.inbound(buffer[offset:]); isReplaced {
			buffers[index] = append(buffer[:offset], translated...)
		}
	}
	return device.Device.Write(buffers, offset)
}
