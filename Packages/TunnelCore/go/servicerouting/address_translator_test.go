package servicerouting

import (
	"bytes"
	"net/netip"
	"sync"
	"testing"
	"time"
)

type addressBook map[netip.Addr]netip.Addr

func (book addressBook) realAddress(fake netip.Addr) (netip.Addr, bool) {
	real, isKnown := book[fake]
	return real, isKnown
}

type manualClock struct {
	current time.Time
}

func (clock *manualClock) now() time.Time {
	return clock.current
}

func (clock *manualClock) advance(duration time.Duration) {
	clock.current = clock.current.Add(duration)
}

type translatorFixture struct {
	translator *addressTranslator
	clock      *manualClock
	book       addressBook
}

func newTranslatorFixture(capacity int) translatorFixture {
	clock := &manualClock{current: time.Unix(1_800_000_000, 0)}
	book := addressBook{fakeIPv4: realIPv4, otherFake: realIPv4, fakeIPv6: realIPv6}
	translator := newAddressTranslator([]netip.Prefix{fakeIPv4s, fakeIPv6s}, book, clock.now, capacity)
	return translatorFixture{translator: translator, clock: clock, book: book}
}

func (fixture translatorFixture) send(t *testing.T, spec segmentSpec) []byte {
	t.Helper()
	packet := packetFor(spec)
	if !fixture.translator.outbound(packet) {
		t.Fatalf("expected the packet to %v to go out", spec.destination)
	}
	return packet
}

func (fixture translatorFixture) receive(spec segmentSpec) []byte {
	packet := packetFor(spec)
	fixture.translator.inbound(packet)
	return packet
}

func port(address netip.Addr, number uint16) netip.AddrPort {
	return netip.AddrPortFrom(address, number)
}

func TestTranslatorSendsTrafficForAFakeAddressToItsRealAddress(t *testing.T) {
	fixture := newTranslatorFixture(maximumTrackedConnections)

	packet := fixture.send(t, tcpSpec(port(deviceIPv4, 50000), port(fakeIPv4, 443), tcpFlagSYN, nil))

	layout, _ := layoutOf(packet)
	if layout.destination(packet) != realIPv4 || layout.destinationPort(packet) != 443 {
		t.Fatalf("expected the segment to go to %v:443, got %v", realIPv4, layout.destination(packet))
	}
	expectValidChecksums(t, packet, layout.transportOffset, protocolTCP)
}

func TestTranslatorAnswersFromTheFakeAddressTheConnectionUsed(t *testing.T) {
	fixture := newTranslatorFixture(maximumTrackedConnections)
	fixture.send(t, tcpSpec(port(deviceIPv4, 50000), port(fakeIPv4, 443), tcpFlagSYN, nil))

	reply := fixture.receive(tcpSpec(port(realIPv4, 443), port(deviceIPv4, 50000), tcpFlagSYN|tcpFlagACK, nil))

	layout, _ := layoutOf(reply)
	if layout.source(reply) != fakeIPv4 {
		t.Fatalf("expected the reply from %v, got %v", fakeIPv4, layout.source(reply))
	}
	expectValidChecksums(t, reply, layout.transportOffset, protocolTCP)
}

func TestTranslatorKeepsTwoFakeAddressesOfOneRealAddressApart(t *testing.T) {
	fixture := newTranslatorFixture(maximumTrackedConnections)
	fixture.send(t, tcpSpec(port(deviceIPv4, 50000), port(fakeIPv4, 443), tcpFlagSYN, nil))
	fixture.send(t, tcpSpec(port(deviceIPv4, 50001), port(otherFake, 443), tcpFlagSYN, nil))

	first := fixture.receive(tcpSpec(port(realIPv4, 443), port(deviceIPv4, 50000), tcpFlagSYN|tcpFlagACK, nil))
	second := fixture.receive(tcpSpec(port(realIPv4, 443), port(deviceIPv4, 50001), tcpFlagSYN|tcpFlagACK, nil))

	firstLayout, _ := layoutOf(first)
	secondLayout, _ := layoutOf(second)
	if firstLayout.source(first) != fakeIPv4 || secondLayout.source(second) != otherFake {
		t.Fatalf("expected replies from %v and %v, got %v and %v", fakeIPv4, otherFake, firstLayout.source(first), secondLayout.source(second))
	}
}

func TestTranslatorLeavesRepliesOfUntrackedConnectionsAlone(t *testing.T) {
	fixture := newTranslatorFixture(maximumTrackedConnections)
	fixture.send(t, tcpSpec(port(deviceIPv4, 50000), port(fakeIPv4, 443), tcpFlagSYN, nil))
	untracked := packetFor(tcpSpec(port(realIPv4, 443), port(deviceIPv4, 50002), tcpFlagSYN|tcpFlagACK, nil))
	original := append([]byte(nil), untracked...)

	fixture.translator.inbound(untracked)

	if !bytes.Equal(untracked, original) {
		t.Fatal("expected a reply to an untracked connection to stay unchanged")
	}
}

func TestTranslatorDropsTrafficForAnUnknownFakeAddress(t *testing.T) {
	fixture := newTranslatorFixture(maximumTrackedConnections)
	packet := packetFor(tcpSpec(port(deviceIPv4, 50000), port(netip.MustParseAddr("198.18.9.9"), 443), tcpFlagSYN, nil))

	if fixture.translator.outbound(packet) {
		t.Fatal("expected traffic for an unknown fake address to be dropped")
	}
}

func TestTranslatorPassesTrafficOutsideTheFakeNetworksUnchanged(t *testing.T) {
	fixture := newTranslatorFixture(maximumTrackedConnections)
	cases := map[string][]byte{
		"real destination": packetFor(tcpSpec(port(deviceIPv4, 50000), port(realIPv4, 443), tcpFlagSYN, nil)),
		"not an IP packet": {0x00, 0x01, 0x02},
	}
	for name, packet := range cases {
		t.Run(name, func(t *testing.T) {
			original := append([]byte(nil), packet...)

			isForwarded := fixture.translator.outbound(packet)

			if !isForwarded || !bytes.Equal(packet, original) {
				t.Fatalf("expected the packet to pass unchanged, forwarded %v", isForwarded)
			}
		})
	}
}

func TestTranslatorDropsTrafficForAFakeAddressItCannotTrack(t *testing.T) {
	fixture := newTranslatorFixture(maximumTrackedConnections)
	cases := map[string][]byte{
		"later fragment": withIPv4Fragment(packetFor(udpSpec(port(deviceIPv4, 50000), port(fakeIPv4, 443), make([]byte, 64))), 8, false),
		"other protocol": withByte(packetFor(udpSpec(port(deviceIPv4, 50000), port(fakeIPv4, 443), nil)), ipv4ProtocolOffset, 1),
	}
	for name, packet := range cases {
		t.Run(name, func(t *testing.T) {
			if fixture.translator.outbound(packet) {
				t.Fatal("expected the packet to be dropped")
			}
		})
	}
}

func TestTranslatorTranslatesIPv6(t *testing.T) {
	fixture := newTranslatorFixture(maximumTrackedConnections)

	request := fixture.send(t, udpSpec(port(deviceIPv6, 50000), port(fakeIPv6, 443), []byte("initial")))
	reply := fixture.receive(udpSpec(port(realIPv6, 443), port(deviceIPv6, 50000), []byte("handshake")))

	requestLayout, _ := layoutOf(request)
	replyLayout, _ := layoutOf(reply)
	if requestLayout.destination(request) != realIPv6 || replyLayout.source(reply) != fakeIPv6 {
		t.Fatalf("expected %v out and %v back, got %v and %v", realIPv6, fakeIPv6, requestLayout.destination(request), replyLayout.source(reply))
	}
	expectValidChecksums(t, request, requestLayout.transportOffset, protocolUDP)
	expectValidChecksums(t, reply, replyLayout.transportOffset, protocolUDP)
}

func TestTranslatorKeepsTheRealAddressOfAnOpenConnection(t *testing.T) {
	fixture := newTranslatorFixture(maximumTrackedConnections)
	fixture.send(t, tcpSpec(port(deviceIPv4, 50000), port(fakeIPv4, 443), tcpFlagSYN, nil))
	fixture.book[fakeIPv4] = netip.MustParseAddr("93.184.216.34")

	packet := fixture.send(t, tcpSpec(port(deviceIPv4, 50000), port(fakeIPv4, 443), tcpFlagACK, nil))

	layout, _ := layoutOf(packet)
	if layout.destination(packet) != realIPv4 {
		t.Fatalf("expected the open connection to stay on %v, got %v", realIPv4, layout.destination(packet))
	}
}

func TestTranslatorRefusesAConnectionThatWouldCollideOnTheWire(t *testing.T) {
	fixture := newTranslatorFixture(maximumTrackedConnections)
	fixture.send(t, tcpSpec(port(deviceIPv4, 50000), port(fakeIPv4, 443), tcpFlagSYN, nil))
	colliding := packetFor(tcpSpec(port(deviceIPv4, 50000), port(otherFake, 443), tcpFlagSYN, nil))

	if fixture.translator.outbound(colliding) {
		t.Fatal("expected a second connection to the same real address and port from the same local port to be dropped")
	}
}

func TestTranslatorForgetsConnectionsAfterTheirTimeouts(t *testing.T) {
	cases := []struct {
		name     string
		protocol uint8
		exchange func(fixture translatorFixture, t *testing.T)
		timeout  time.Duration
	}{
		{"UDP mapping", protocolUDP, exchangeUDP, udpMappingTimeout},
		{"unanswered TCP connection", protocolTCP, sendSYN, transitoryTCPTimeout},
		{"established TCP connection", protocolTCP, establishTCP, establishedTCPTimeout},
		{"TCP connection closed by both sides", protocolTCP, closeTCP, transitoryTCPTimeout},
		{"reset TCP connection", protocolTCP, resetTCP, transitoryTCPTimeout},
	}
	for _, testCase := range cases {
		t.Run(testCase.name, func(t *testing.T) {
			expectReplyTranslated := func(fixture translatorFixture, isExpected bool) {
				t.Helper()
				reply := fixture.receive(segmentSpec{protocol: testCase.protocol, source: port(realIPv4, 443),
					destination: port(deviceIPv4, 50000), tcpFlags: tcpFlagACK})
				layout, _ := layoutOf(reply)
				if (layout.source(reply) == fakeIPv4) != isExpected {
					t.Fatalf("expected the reply translated: %v, source %v", isExpected, layout.source(reply))
				}
			}
			stillTracked := newTranslatorFixture(maximumTrackedConnections)
			testCase.exchange(stillTracked, t)
			stillTracked.clock.advance(testCase.timeout - time.Second)
			expired := newTranslatorFixture(maximumTrackedConnections)
			testCase.exchange(expired, t)
			expired.clock.advance(testCase.timeout + time.Second)

			expectReplyTranslated(stillTracked, true)
			expectReplyTranslated(expired, false)
		})
	}
}

func TestTranslatorEvictsTheLeastRecentlyUsedConnectionWhenFull(t *testing.T) {
	fixture := newTranslatorFixture(2)
	fixture.send(t, udpSpec(port(deviceIPv4, 50001), port(fakeIPv4, 443), nil))
	fixture.clock.advance(time.Second)
	fixture.send(t, udpSpec(port(deviceIPv4, 50002), port(fakeIPv4, 443), nil))
	fixture.clock.advance(time.Second)
	fixture.send(t, udpSpec(port(deviceIPv4, 50001), port(fakeIPv4, 443), nil))
	fixture.clock.advance(time.Second)

	fixture.send(t, udpSpec(port(deviceIPv4, 50003), port(fakeIPv4, 443), nil))

	for localPort, isTracked := range map[uint16]bool{50001: true, 50002: false, 50003: true} {
		reply := fixture.receive(udpSpec(port(realIPv4, 443), port(deviceIPv4, localPort), nil))
		layout, _ := layoutOf(reply)
		if (layout.source(reply) == fakeIPv4) != isTracked {
			t.Fatalf("port %d: expected tracked %v, reply source %v", localPort, isTracked, layout.source(reply))
		}
	}
}

func TestTranslatorServesBothDirectionsConcurrently(t *testing.T) {
	fixture := newTranslatorFixture(maximumTrackedConnections)
	var group sync.WaitGroup
	for direction := range 2 {
		group.Go(func() {
			for index := range 1000 {
				localPort := uint16(40000 + index%64)
				if direction == 0 {
					fixture.translator.outbound(packetFor(udpSpec(port(deviceIPv4, localPort), port(fakeIPv4, 443), nil)))
				} else {
					fixture.translator.inbound(packetFor(udpSpec(port(realIPv4, 443), port(deviceIPv4, localPort), nil)))
				}
			}
		})
	}

	group.Wait()
}

func exchangeUDP(fixture translatorFixture, t *testing.T) {
	fixture.send(t, udpSpec(port(deviceIPv4, 50000), port(fakeIPv4, 443), nil))
	fixture.receive(udpSpec(port(realIPv4, 443), port(deviceIPv4, 50000), nil))
}

func sendSYN(fixture translatorFixture, t *testing.T) {
	fixture.send(t, tcpSpec(port(deviceIPv4, 50000), port(fakeIPv4, 443), tcpFlagSYN, nil))
}

func establishTCP(fixture translatorFixture, t *testing.T) {
	sendSYN(fixture, t)
	fixture.receive(tcpSpec(port(realIPv4, 443), port(deviceIPv4, 50000), tcpFlagSYN|tcpFlagACK, nil))
	fixture.send(t, tcpSpec(port(deviceIPv4, 50000), port(fakeIPv4, 443), tcpFlagACK, nil))
}

func closeTCP(fixture translatorFixture, t *testing.T) {
	establishTCP(fixture, t)
	fixture.send(t, tcpSpec(port(deviceIPv4, 50000), port(fakeIPv4, 443), tcpFlagFIN|tcpFlagACK, nil))
	fixture.receive(tcpSpec(port(realIPv4, 443), port(deviceIPv4, 50000), tcpFlagFIN|tcpFlagACK, nil))
}

func resetTCP(fixture translatorFixture, t *testing.T) {
	establishTCP(fixture, t)
	fixture.receive(tcpSpec(port(realIPv4, 443), port(deviceIPv4, 50000), tcpFlagRST, nil))
}
