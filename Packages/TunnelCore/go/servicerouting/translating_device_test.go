package servicerouting

import (
	"net/netip"
	"os"
	"testing"

	"golang.org/x/net/dns/dnsmessage"
	"golang.zx2c4.com/wireguard/tun"
)

const testOffset = 16

type recordingDevice struct {
	outgoing [][]byte
	written  [][]byte
}

func (device *recordingDevice) File() *os.File { return nil }

func (device *recordingDevice) Read(buffers [][]byte, sizes []int, offset int) (int, error) {
	for index, packet := range device.outgoing {
		sizes[index] = copy(buffers[index][offset:], packet)
	}
	return len(device.outgoing), nil
}

func (device *recordingDevice) Write(buffers [][]byte, offset int) (int, error) {
	for _, buffer := range buffers {
		device.written = append(device.written, append([]byte(nil), buffer[offset:]...))
	}
	return len(buffers), nil
}

func (device *recordingDevice) MTU() (int, error) { return 1420, nil }

func (device *recordingDevice) Name() (string, error) { return "recording", nil }

func (device *recordingDevice) Events() <-chan tun.Event { return nil }

func (device *recordingDevice) Close() error { return nil }

func (device *recordingDevice) BatchSize() int { return 1 }

func TestTranslatingDeviceDropsOutgoingPacketsToUnknownFakeAddresses(t *testing.T) {
	inner := &recordingDevice{outgoing: [][]byte{
		tcpPacket(deviceAddress, netip.MustParseAddr("198.19.200.1"), 50000, 443, nil),
		tcpPacket(deviceAddress, unrelatedAddress, 50000, 443, nil),
	}}
	device := NewTranslatingDevice(inner, testPlan)
	buffers, sizes := [][]byte{make([]byte, 2048), make([]byte, 2048)}, make([]int, 2)

	count, err := device.Read(buffers, sizes, testOffset)

	if err != nil || count != 2 || sizes[0] != 0 || sizes[1] == 0 {
		t.Fatalf("expected the first packet dropped and the second kept, got sizes %v", sizes)
	}
}

func TestTranslatingDeviceWritesAShorterAnswerInPlace(t *testing.T) {
	inner := &recordingDevice{}
	device := NewTranslatingDevice(inner, testPlan)
	response := dnsResponse(t, "api.ipify.org.", dnsmessage.TypeAAAA, func(builder *dnsmessage.Builder) {
		builder.AAAAResource(answerHeader("api.ipify.org.", dnsmessage.TypeAAAA, 300), dnsmessage.AAAAResource{AAAA: netip.MustParseAddr("2606:4700::6810:a8b").As16()})
	})
	packet := udpPacket(testPlan.UpstreamDNS, deviceAddress, 53, 53000, response)
	buffer := make([]byte, testOffset, 4096)
	buffer = append(buffer, packet...)

	if _, err := device.Write([][]byte{buffer}, testOffset); err != nil {
		t.Fatal(err)
	}

	if len(inner.written) != 1 || len(inner.written[0]) >= len(packet) || sourceOf(inner.written[0]) != testPlan.VirtualDNS {
		t.Fatalf("expected a shorter answer from the virtual resolver, got %d bytes", len(inner.written[0]))
	}
	expectValidChecksums(t, inner.written[0])
}
