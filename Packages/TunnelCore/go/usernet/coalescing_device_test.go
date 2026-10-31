package usernet

import (
	"bytes"
	"errors"
	"os"
	"testing"
	"time"

	"golang.zx2c4.com/wireguard/tun"
)

const testDeviceMTU = 1500

type scriptedDevice struct {
	packets chan []byte
	events  chan tun.Event
}

func newScriptedDevice() *scriptedDevice {
	return &scriptedDevice{packets: make(chan []byte, 16), events: make(chan tun.Event)}
}

func (device *scriptedDevice) File() *os.File { return nil }

func (device *scriptedDevice) Read(buffers [][]byte, sizes []int, offset int) (int, error) {
	packet, ok := <-device.packets
	if !ok {
		return 0, os.ErrClosed
	}
	sizes[0] = copy(buffers[0][offset:], packet)
	return 1, nil
}

func (device *scriptedDevice) Write(buffers [][]byte, offset int) (int, error) {
	return len(buffers), nil
}

func (device *scriptedDevice) MTU() (int, error) { return testDeviceMTU, nil }

func (device *scriptedDevice) Name() (string, error) { return "scripted", nil }

func (device *scriptedDevice) Events() <-chan tun.Event { return device.events }

func (device *scriptedDevice) Close() error {
	close(device.packets)
	return nil
}

func (device *scriptedDevice) BatchSize() int { return 1 }

func startCoalescingDevice(t *testing.T) (*scriptedDevice, *coalescingDevice) {
	t.Helper()
	inner := newScriptedDevice()
	device, err := newCoalescingDevice(inner)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { device.Close() })
	return inner, device
}

func readPackets(t *testing.T, device *coalescingDevice) [][]byte {
	t.Helper()
	buffers, sizes := make([][]byte, coalescingReadBatchSize), make([]int, coalescingReadBatchSize)
	for index := range buffers {
		buffers[index] = make([]byte, testDeviceMTU+16)
	}
	count, err := device.Read(buffers, sizes, 16)
	if err != nil {
		t.Fatal(err)
	}
	packets := make([][]byte, count)
	for index := range count {
		packets[index] = buffers[index][16 : 16+sizes[index]]
	}
	return packets
}

func TestCoalescingDeviceReleasesAHeldAcknowledgementAfterTheHoldDuration(t *testing.T) {
	inner, device := startCoalescingDevice(t)
	acknowledgement := pureAcknowledgement(1000).packet()
	started := time.Now()

	inner.packets <- acknowledgement
	packets := readPackets(t, device)

	if len(packets) != 1 || !bytes.Equal(packets[0], acknowledgement) {
		t.Fatalf("expected the held acknowledgement, got %d packets", len(packets))
	}
	if elapsed := time.Since(started); elapsed < acknowledgementHoldDuration {
		t.Fatalf("expected the acknowledgement after %v, got it after %v", acknowledgementHoldDuration, elapsed)
	}
}

func TestCoalescingDeviceSendsTheNewestOfSeveralAcknowledgements(t *testing.T) {
	inner, device := startCoalescingDevice(t)
	newest := pureAcknowledgement(9000).packet()

	inner.packets <- pureAcknowledgement(1000).packet()
	inner.packets <- pureAcknowledgement(5000).packet()
	inner.packets <- newest
	packets := readPackets(t, device)

	if len(packets) != 1 || !bytes.Equal(packets[0], newest) {
		t.Fatalf("expected only the newest acknowledgement, got %d packets", len(packets))
	}
}

func TestCoalescingDeviceDeliversDataAtOnce(t *testing.T) {
	inner, device := startCoalescingDevice(t)
	data := testSegment{
		source: clientAddress4, destination: serverAddress4, flags: flagAcknowledgement | flagPush, payloadLength: 512,
	}.packet()

	inner.packets <- data
	packets := readPackets(t, device)

	if len(packets) != 1 || !bytes.Equal(packets[0], data) {
		t.Fatalf("expected the data segment, got %d packets", len(packets))
	}
}

func TestCoalescingDeviceStopsReadingWhenClosed(t *testing.T) {
	inner := newScriptedDevice()
	device, err := newCoalescingDevice(inner)
	if err != nil {
		t.Fatal(err)
	}

	device.Close()

	buffers, sizes := [][]byte{make([]byte, testDeviceMTU)}, []int{0}
	if _, err := device.Read(buffers, sizes, 0); !errors.Is(err, os.ErrClosed) {
		t.Fatalf("expected a closed device, got %v", err)
	}
}
