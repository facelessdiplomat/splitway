package udpbind

import (
	"fmt"
	"testing"

	"golang.zx2c4.com/wireguard/conn"
)

const transportDatagramByteCount = 1452

func BenchmarkBindDeliversADatagram(b *testing.B) {
	benchmarkDelivery(b, func() conn.Bind { return New() })
}

func BenchmarkStandardBindDeliversADatagram(b *testing.B) {
	benchmarkDelivery(b, conn.NewStdNetBind)
}

func benchmarkDelivery(b *testing.B, newBind func() conn.Bind) {
	sender, receiver := newBind(), newBind()
	if _, _, err := sender.Open(0); err != nil {
		b.Fatal(err)
	}
	defer sender.Close()
	receivers, port, err := receiver.Open(0)
	if err != nil {
		b.Fatal(err)
	}
	defer receiver.Close()
	endpoint, err := sender.ParseEndpoint(fmt.Sprintf("127.0.0.1:%d", port))
	if err != nil {
		b.Fatal(err)
	}
	datagram := [][]byte{make([]byte, transportDatagramByteCount)}
	packets := [][]byte{make([]byte, transportDatagramByteCount)}
	sizes := make([]int, 1)
	endpoints := make([]conn.Endpoint, 1)
	b.SetBytes(transportDatagramByteCount)
	b.ReportAllocs()
	for b.Loop() {
		if err := sender.Send(datagram, endpoint); err != nil {
			b.Fatal(err)
		}
		if _, err := receivers[0](packets, sizes, endpoints); err != nil {
			b.Fatal(err)
		}
	}
}
