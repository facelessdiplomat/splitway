package servicerouting

import (
	"encoding/binary"
	"net/netip"
	"testing"
	"time"

	"golang.org/x/net/dns/dnsmessage"
	"golang.zx2c4.com/wireguard/tun/tuntest"
)

const (
	testDeviceOffset  = 16
	testBufferSize    = 2048
	testReceiveWindow = 2 * time.Second
	testClientPort    = 53000
)

var (
	virtualDNS  = netip.MustParseAddr("198.18.0.2")
	upstreamDNS = netip.MustParseAddr("1.1.1.1")
)

func testPlan() Plan {
	return Plan{VirtualDNS: virtualDNS, UpstreamDNS: upstreamDNS, FakeIPv4Network: fakeIPv4s, FakeIPv6Network: fakeIPv6s}
}

type deviceFixture struct {
	channel *tuntest.ChannelTUN
	device  *TranslatingDevice
}

func newDeviceFixture(t *testing.T) deviceFixture {
	t.Helper()
	fixture := newDeviceFixtureWithoutPlan()
	if err := fixture.device.Apply(testPlan()); err != nil {
		t.Fatal(err)
	}
	return fixture
}

func newDeviceFixtureWithoutPlan() deviceFixture {
	channel := tuntest.NewChannelTUN()
	return deviceFixture{channel: channel, device: NewTranslatingDevice(channel.TUN())}
}

func (fixture deviceFixture) resolve(t *testing.T, name string) netip.Addr {
	t.Helper()
	client := port(deviceIPv4, testClientPort)
	fixture.readFromSystem(t, packetFor(udpSpec(client, port(virtualDNS, dnsPort), dnsQuery(t, name, dnsmessage.TypeA))))
	upstreamAnswer := dnsResponse(t, name, dnsmessage.TypeA, []answerSpec{
		{name: name, kind: dnsmessage.TypeA, ttl: 300, address: realIPv4},
	})
	answer, _ := fixture.writeToSystem(t, packetFor(udpSpec(port(upstreamDNS, dnsPort), client, upstreamAnswer)))
	return expectFakeAnswer(t, answer)
}

func (fixture deviceFixture) connect(t *testing.T, fake netip.Addr) (netip.Addr, bool) {
	t.Helper()
	syn, isForwarded := fixture.readFromSystem(t, packetFor(tcpSpec(port(deviceIPv4, 50000), port(fake, 443), tcpFlagSYN, nil)))
	if !isForwarded {
		return netip.Addr{}, false
	}
	layout, _ := layoutOf(syn)
	return layout.destination(syn), true
}

func (fixture deviceFixture) readFromSystem(t *testing.T, packet []byte) ([]byte, bool) {
	t.Helper()
	go func() { fixture.channel.Outbound <- packet }()
	buffers := [][]byte{make([]byte, testBufferSize)}
	sizes := []int{0}
	count, err := fixture.device.Read(buffers, sizes, testDeviceOffset)
	if err != nil || count != 1 {
		t.Fatalf("expected one packet, got %d: %v", count, err)
	}
	return buffers[0][testDeviceOffset : testDeviceOffset+sizes[0]], sizes[0] > 0
}

func (fixture deviceFixture) writeToSystem(t *testing.T, packet []byte) ([]byte, bool) {
	t.Helper()
	buffer := append(make([]byte, testDeviceOffset), packet...)
	written := make(chan error, 1)
	go func() {
		_, err := fixture.device.Write([][]byte{buffer}, testDeviceOffset)
		written <- err
	}()
	select {
	case delivered := <-fixture.channel.Inbound:
		if err := <-written; err != nil {
			t.Fatal(err)
		}
		return delivered, true
	case err := <-written:
		if err != nil {
			t.Fatal(err)
		}
		return nil, false
	case <-time.After(testReceiveWindow):
		t.Fatal("the write did not finish")
	}
	return nil, false
}

func TestDeviceAnswersASelectedNameWithAFakeAddressAndTranslatesItsConnection(t *testing.T) {
	fixture := newDeviceFixture(t)
	client := port(deviceIPv4, testClientPort)

	query, _ := fixture.readFromSystem(t, packetFor(udpSpec(client, port(virtualDNS, dnsPort), dnsQuery(t, "api.example.com.", dnsmessage.TypeA))))
	upstreamAnswer := dnsResponse(t, "api.example.com.", dnsmessage.TypeA, []answerSpec{
		{name: "api.example.com.", kind: dnsmessage.TypeA, ttl: 300, address: realIPv4},
	})
	answer, _ := fixture.writeToSystem(t, packetFor(udpSpec(port(upstreamDNS, dnsPort), client, upstreamAnswer)))
	fake := expectFakeAnswer(t, answer)
	syn, _ := fixture.readFromSystem(t, packetFor(tcpSpec(port(deviceIPv4, 50000), port(fake, 443), tcpFlagSYN, nil)))
	synAcknowledgement, _ := fixture.writeToSystem(t, packetFor(tcpSpec(port(realIPv4, 443), port(deviceIPv4, 50000), tcpFlagSYN|tcpFlagACK, nil)))

	queryLayout, _ := layoutOf(query)
	if queryLayout.destination(query) != upstreamDNS {
		t.Fatalf("expected the query to go to %v, got %v", upstreamDNS, queryLayout.destination(query))
	}
	expectValidChecksums(t, query, queryLayout.transportOffset, protocolUDP)
	synLayout, _ := layoutOf(syn)
	acknowledgementLayout, _ := layoutOf(synAcknowledgement)
	if synLayout.destination(syn) != realIPv4 || acknowledgementLayout.source(synAcknowledgement) != fake {
		t.Fatalf("expected the connection to %v through %v, got %v and %v", realIPv4, fake,
			synLayout.destination(syn), acknowledgementLayout.source(synAcknowledgement))
	}
}

func TestDeviceDropsTCPQueriesForTheVirtualResolver(t *testing.T) {
	fixture := newDeviceFixture(t)

	_, isForwarded := fixture.readFromSystem(t, packetFor(tcpSpec(port(deviceIPv4, testClientPort), port(virtualDNS, dnsPort), tcpFlagSYN, nil)))

	if isForwarded {
		t.Fatal("expected a TCP query to be dropped")
	}
}

func TestDeviceDropsTrafficForAnUnknownFakeAddress(t *testing.T) {
	fixture := newDeviceFixture(t)

	_, isForwarded := fixture.readFromSystem(t, packetFor(tcpSpec(port(deviceIPv4, 50000), port(fakeIPv4, 443), tcpFlagSYN, nil)))

	if isForwarded {
		t.Fatal("expected traffic for an unknown fake address to be dropped")
	}
}

func TestDeviceDropsADatagramFromTheUpstreamResolverThatEndsInsideItsHeader(t *testing.T) {
	fixture := newDeviceFixture(t)
	answer := packetFor(udpSpec(port(upstreamDNS, dnsPort), port(deviceIPv4, testClientPort), []byte("answer")))
	binary.BigEndian.PutUint16(answer[ipv4TotalLengthOffset:], ipv4MinimumHeaderByteCount+udpHeaderByteCount-2)

	_, isDelivered := fixture.writeToSystem(t, answer)

	if isDelivered {
		t.Fatal("expected a cut datagram from the upstream resolver to be dropped")
	}
}

func TestDeviceLeavesAnswersWithoutAQueryAlone(t *testing.T) {
	fixture := newDeviceFixture(t)
	upstreamAnswer := dnsResponse(t, "api.example.com.", dnsmessage.TypeA, []answerSpec{
		{name: "api.example.com.", kind: dnsmessage.TypeA, ttl: 300, address: realIPv4},
	})
	unsolicited := packetFor(udpSpec(port(upstreamDNS, dnsPort), port(deviceIPv4, testClientPort), upstreamAnswer))

	delivered, _ := fixture.writeToSystem(t, unsolicited)

	if string(delivered) != string(unsolicited) {
		t.Fatal("expected an answer nobody asked for through the virtual resolver to stay unchanged")
	}
}

func TestDeviceForgetsAQueryThatWasNotAnsweredInTime(t *testing.T) {
	fixture := newDeviceFixture(t)
	clock := &manualClock{current: time.Unix(1_800_000_000, 0)}
	fixture.device.router.Store(newServiceRouter(testPlan(), clock.now))
	client := port(deviceIPv4, testClientPort)
	fixture.readFromSystem(t, packetFor(udpSpec(client, port(virtualDNS, dnsPort), dnsQuery(t, "api.example.com.", dnsmessage.TypeA))))
	clock.advance(pendingQueryTimeout + time.Second)
	upstreamAnswer := dnsResponse(t, "api.example.com.", dnsmessage.TypeA, []answerSpec{
		{name: "api.example.com.", kind: dnsmessage.TypeA, ttl: 300, address: realIPv4},
	})
	late := packetFor(udpSpec(port(upstreamDNS, dnsPort), client, upstreamAnswer))

	delivered, _ := fixture.writeToSystem(t, late)

	if string(delivered) != string(late) {
		t.Fatal("expected a late answer to stay unchanged")
	}
}

func TestDeviceRejectsAnInvalidPlan(t *testing.T) {
	valid := testPlan()
	cases := map[string]func(*Plan){
		"virtual resolver is IPv6":      func(plan *Plan) { plan.VirtualDNS = netip.MustParseAddr("fdc6:8b52::2") },
		"virtual resolver outside":      func(plan *Plan) { plan.VirtualDNS = netip.MustParseAddr("10.0.0.2") },
		"virtual resolver among fakes":  func(plan *Plan) { plan.VirtualDNS = netip.MustParseAddr("198.18.1.0") },
		"upstream resolver is IPv6":     func(plan *Plan) { plan.UpstreamDNS = netip.MustParseAddr("2606:4700:4700::1111") },
		"upstream resolver among fakes": func(plan *Plan) { plan.UpstreamDNS = netip.MustParseAddr("198.18.5.5") },
		"fake IPv4 network too small":   func(plan *Plan) { plan.FakeIPv4Network = netip.MustParsePrefix("198.18.0.0/24") },
		"fake IPv4 network is IPv6":     func(plan *Plan) { plan.FakeIPv4Network = fakeIPv6s },
		"fake IPv6 network is IPv4":     func(plan *Plan) { plan.FakeIPv6Network = netip.MustParsePrefix("10.0.0.0/8") },
		"fake IPv6 network too small":   func(plan *Plan) { plan.FakeIPv6Network = netip.MustParsePrefix("fdc6:8b52::/121") },
		"fake IPv4 network host bits":   func(plan *Plan) { plan.FakeIPv4Network = netip.MustParsePrefix("198.18.0.1/15") },
		"fake IPv6 network host bits":   func(plan *Plan) { plan.FakeIPv6Network = netip.MustParsePrefix("fdc6:8b52::1/64") },
		"fake IPv4 network not given":   func(plan *Plan) { plan.FakeIPv4Network = netip.Prefix{} },
		"virtual resolver not given":    func(plan *Plan) { plan.VirtualDNS = netip.Addr{} },
		"upstream resolver not given":   func(plan *Plan) { plan.UpstreamDNS = netip.Addr{} },
	}
	for name, change := range cases {
		t.Run(name, func(t *testing.T) {
			plan := valid
			change(&plan)

			if err := newDeviceFixtureWithoutPlan().device.Apply(plan); err == nil {
				t.Fatal("expected the plan to be rejected")
			}
		})
	}
}

func TestDeviceAcceptsAPlanWithoutIPv6(t *testing.T) {
	plan := testPlan()
	plan.FakeIPv6Network = netip.Prefix{}

	if err := newDeviceFixtureWithoutPlan().device.Apply(plan); err != nil {
		t.Fatal(err)
	}
}

func TestDevicePassesPacketsUnchangedUntilAPlanArrives(t *testing.T) {
	fixture := newDeviceFixtureWithoutPlan()
	client := port(deviceIPv4, testClientPort)
	query := packetFor(udpSpec(client, port(virtualDNS, dnsPort), dnsQuery(t, "api.example.com.", dnsmessage.TypeA)))
	answer := packetFor(udpSpec(port(upstreamDNS, dnsPort), client, dnsResponse(t, "api.example.com.", dnsmessage.TypeA, []answerSpec{
		{name: "api.example.com.", kind: dnsmessage.TypeA, ttl: 300, address: realIPv4},
	})))

	forwarded, _ := fixture.readFromSystem(t, query)
	delivered, _ := fixture.writeToSystem(t, answer)

	if string(forwarded) != string(query) || string(delivered) != string(answer) {
		t.Fatal("expected packets to pass unchanged before the first plan")
	}
}

func TestDeviceKeepsItsFakeAddressesWhenTheSamePlanArrivesAgain(t *testing.T) {
	fixture := newDeviceFixture(t)
	fake := fixture.resolve(t, "api.example.com.")

	err := fixture.device.Apply(testPlan())
	destination, isForwarded := fixture.connect(t, fake)

	if err != nil {
		t.Fatal(err)
	}
	if !isForwarded || destination != realIPv4 {
		t.Fatalf("expected the connection to reach %v, got %v", realIPv4, destination)
	}
}

func TestDeviceForgetsItsFakeAddressesWhenAnotherPlanArrives(t *testing.T) {
	fixture := newDeviceFixture(t)
	fake := fixture.resolve(t, "api.example.com.")
	another := testPlan()
	another.UpstreamDNS = netip.MustParseAddr("9.9.9.9")

	err := fixture.device.Apply(another)
	_, isForwarded := fixture.connect(t, fake)

	if err != nil {
		t.Fatal(err)
	}
	if isForwarded {
		t.Fatal("expected a fake address of the previous plan to be unknown")
	}
}

func TestDeviceKeepsTheCurrentPlanWhenAnInvalidOneArrives(t *testing.T) {
	fixture := newDeviceFixture(t)
	fake := fixture.resolve(t, "api.example.com.")

	err := fixture.device.Apply(Plan{})
	destination, isForwarded := fixture.connect(t, fake)

	if err == nil {
		t.Fatal("expected the empty plan to be rejected")
	}
	if !isForwarded || destination != realIPv4 {
		t.Fatalf("expected the connection to reach %v, got %v", realIPv4, destination)
	}
}

func expectFakeAnswer(t *testing.T, packet []byte) netip.Addr {
	t.Helper()
	layout, isParsed := layoutOf(packet)
	if !isParsed || !layout.hasPorts || layout.source(packet) != virtualDNS || layout.sourcePort(packet) != dnsPort {
		t.Fatalf("expected an answer from the virtual resolver, got %+v", layout)
	}
	expectValidChecksums(t, packet, layout.transportOffset, protocolUDP)
	if int(binary.BigEndian.Uint16(packet[layout.transportOffset+udpLengthOffset:])) != layout.packetEnd-layout.transportOffset {
		t.Fatal("the UDP length does not match the datagram")
	}
	parsed := parseResponse(t, packet[layout.transportOffset+udpHeaderByteCount:layout.packetEnd])
	if len(parsed.answers) != 1 || !fakeIPv4s.Contains(addressOf(parsed.answers[0])) {
		t.Fatalf("expected one fake address, got %+v", parsed.answers)
	}
	return addressOf(parsed.answers[0])
}
