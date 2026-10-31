package usernet

import (
	"testing"
)

func TestParseTCPSegmentReadsAPureAcknowledgement(t *testing.T) {
	testCases := []struct {
		name    string
		segment testSegment
	}{
		{name: "IPv4", segment: pureAcknowledgement(1000)},
		{name: "IPv6", segment: testSegment{
			source: clientAddress6, destination: serverAddress6, sourcePort: 50000, destinationPort: 443,
			flags: flagAcknowledgement, acknowledgement: 1000,
		}},
	}

	for _, testCase := range testCases {
		t.Run(testCase.name, func(t *testing.T) {
			segment, ok := parseTCPSegment(testCase.segment.packet())

			if !ok || !segment.isPureAcknowledgement || segment.acknowledgement != 1000 {
				t.Fatalf("expected a pure acknowledgement of 1000, got %+v ok=%v", segment, ok)
			}
			expected := tcpFlow{
				source: testCase.segment.source, destination: testCase.segment.destination,
				sourcePort: 50000, destinationPort: 443,
			}
			if segment.flow != expected {
				t.Fatalf("expected the flow %+v, got %+v", expected, segment.flow)
			}
		})
	}
}

func TestParseTCPSegmentTellsOtherSegmentsFromPureAcknowledgements(t *testing.T) {
	testCases := []struct {
		name    string
		segment testSegment
	}{
		{name: "data", segment: testSegment{source: clientAddress4, destination: serverAddress4, flags: flagAcknowledgement, payloadLength: 100}},
		{name: "push", segment: testSegment{source: clientAddress4, destination: serverAddress4, flags: flagAcknowledgement | flagPush}},
		{name: "finish", segment: testSegment{source: clientAddress4, destination: serverAddress4, flags: flagAcknowledgement | flagFin}},
		{name: "reset", segment: testSegment{source: clientAddress4, destination: serverAddress4, flags: flagReset}},
		{name: "synchronize", segment: testSegment{source: clientAddress4, destination: serverAddress4, flags: flagSyn}},
		{name: "congestion echo", segment: testSegment{source: clientAddress4, destination: serverAddress4, flags: flagAcknowledgement | flagECNEcho}},
	}

	for _, testCase := range testCases {
		t.Run(testCase.name, func(t *testing.T) {
			segment, ok := parseTCPSegment(testCase.segment.packet())

			if !ok || segment.isPureAcknowledgement {
				t.Fatalf("expected a TCP segment that is not a pure acknowledgement, got %+v ok=%v", segment, ok)
			}
		})
	}
}

func TestParseTCPSegmentIgnoresPacketsThatAreNotWholeTCPSegments(t *testing.T) {
	fragment := pureAcknowledgement(1000).packet()
	fragment[6] = 0x20
	udp := ipPacket(clientAddress4, serverAddress4, udpProtocolNumber, make([]byte, 8))
	truncated := pureAcknowledgement(1000).packet()[:30]
	testCases := []struct {
		name   string
		packet []byte
	}{
		{name: "empty", packet: nil},
		{name: "UDP", packet: udp},
		{name: "fragment", packet: fragment},
		{name: "truncated", packet: truncated},
		{name: "unknown version", packet: append([]byte{0x50}, make([]byte, 39)...)},
	}

	for _, testCase := range testCases {
		t.Run(testCase.name, func(t *testing.T) {
			if segment, ok := parseTCPSegment(testCase.packet); ok {
				t.Fatalf("expected no TCP segment, got %+v", segment)
			}
		})
	}
}

func FuzzParseTCPSegment(f *testing.F) {
	f.Add(pureAcknowledgement(1000).packet())
	f.Add(testSegment{source: clientAddress6, destination: serverAddress6, flags: flagAcknowledgement, payloadLength: 10}.packet())
	f.Add([]byte{0x45})

	f.Fuzz(func(t *testing.T, packet []byte) {
		parseTCPSegment(packet)
	})
}
