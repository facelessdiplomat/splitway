package usernet

import (
	"bytes"
	"testing"
	"time"
)

var coalescerStart = time.Date(2026, 10, 31, 12, 0, 0, 0, time.UTC)

func newTestCoalescer() *acknowledgementCoalescer {
	return newAcknowledgementCoalescer(time.Millisecond, 64*1024)
}

func expectPackets(t *testing.T, actual [][]byte, expected ...[]byte) {
	t.Helper()
	if len(actual) != len(expected) {
		t.Fatalf("expected %d packets, got %d", len(expected), len(actual))
	}
	for index := range expected {
		if !bytes.Equal(actual[index], expected[index]) {
			t.Fatalf("packet %d differs from the expected one", index)
		}
	}
}

func TestCoalescerHoldsAPureAcknowledgementUntilItsDeadline(t *testing.T) {
	coalescer := newTestCoalescer()
	acknowledgement := pureAcknowledgement(1000).packet()

	expectPackets(t, coalescer.accept(acknowledgement, coalescerStart))
	expectPackets(t, coalescer.expire(coalescerStart.Add(999*time.Microsecond)))
	expectPackets(t, coalescer.expire(coalescerStart.Add(time.Millisecond)), acknowledgement)
}

func TestCoalescerReplacesAHeldAcknowledgementWithANewerOne(t *testing.T) {
	coalescer := newTestCoalescer()
	older, newer := pureAcknowledgement(1000).packet(), pureAcknowledgement(3800).packet()

	coalescer.accept(older, coalescerStart)
	expectPackets(t, coalescer.accept(newer, coalescerStart.Add(100*time.Microsecond)))

	expectPackets(t, coalescer.expire(coalescerStart.Add(time.Millisecond)), newer)
}

func TestCoalescerSendsTheHeldAcknowledgementBeforeDataOfTheSameConnection(t *testing.T) {
	coalescer := newTestCoalescer()
	acknowledgement := pureAcknowledgement(1000).packet()
	data := testSegment{
		source: clientAddress4, destination: serverAddress4, sourcePort: 50000, destinationPort: 443,
		flags: flagAcknowledgement | flagPush, acknowledgement: 1000, payloadLength: 200,
	}.packet()

	coalescer.accept(acknowledgement, coalescerStart)

	expectPackets(t, coalescer.accept(data, coalescerStart), acknowledgement, data)
	expectPackets(t, coalescer.expire(coalescerStart.Add(time.Second)))
}

func TestCoalescerSendsADuplicateAcknowledgementAtOnce(t *testing.T) {
	coalescer := newTestCoalescer()
	first, duplicate := pureAcknowledgement(1000).packet(), pureAcknowledgement(1000).packet()

	coalescer.accept(first, coalescerStart)

	expectPackets(t, coalescer.accept(duplicate, coalescerStart), first, duplicate)
}

func TestCoalescerKeepsConnectionsApart(t *testing.T) {
	coalescer := newTestCoalescer()
	first := pureAcknowledgement(1000).packet()
	otherConnection := pureAcknowledgement(5000)
	otherConnection.destination = otherAddress4
	second := otherConnection.packet()

	coalescer.accept(first, coalescerStart)
	expectPackets(t, coalescer.accept(second, coalescerStart.Add(500*time.Microsecond)))

	expectPackets(t, coalescer.expire(coalescerStart.Add(time.Millisecond)), first)
	expectPackets(t, coalescer.expire(coalescerStart.Add(1500*time.Microsecond)), second)
}

func TestCoalescerSendsAnAcknowledgementThatStretchesTooFarAtOnce(t *testing.T) {
	coalescer := newTestCoalescer()
	first, far := pureAcknowledgement(1000).packet(), pureAcknowledgement(1000+64*1024).packet()

	coalescer.accept(first, coalescerStart)

	expectPackets(t, coalescer.accept(far, coalescerStart), far)
	expectPackets(t, coalescer.expire(coalescerStart.Add(time.Second)))
}

func TestCoalescerComparesAcknowledgementsAcrossTheSequenceWrap(t *testing.T) {
	coalescer := newTestCoalescer()
	beforeWrap, afterWrap := pureAcknowledgement(0xFFFF_FF00).packet(), pureAcknowledgement(0x100).packet()

	coalescer.accept(beforeWrap, coalescerStart)

	expectPackets(t, coalescer.accept(afterWrap, coalescerStart))
	expectPackets(t, coalescer.expire(coalescerStart.Add(time.Millisecond)), afterWrap)
}

func TestCoalescerPassesOtherPacketsThrough(t *testing.T) {
	coalescer := newTestCoalescer()
	udp := ipPacket(clientAddress4, serverAddress4, udpProtocolNumber, make([]byte, 8))
	synchronize := testSegment{source: clientAddress4, destination: serverAddress4, flags: flagSyn}.packet()

	expectPackets(t, coalescer.accept(udp, coalescerStart), udp)
	expectPackets(t, coalescer.accept(synchronize, coalescerStart), synchronize)
}

func TestCoalescerReportsTheEarliestDeadline(t *testing.T) {
	coalescer := newTestCoalescer()
	if _, ok := coalescer.nextDeadline(); ok {
		t.Fatal("expected no deadline without held acknowledgements")
	}

	coalescer.accept(pureAcknowledgement(1000).packet(), coalescerStart)

	if deadline, ok := coalescer.nextDeadline(); !ok || !deadline.Equal(coalescerStart.Add(time.Millisecond)) {
		t.Fatalf("expected the deadline one millisecond later, got %v ok=%v", deadline, ok)
	}
}

func TestCoalescerReleasesEveryHeldAcknowledgementWhenDrained(t *testing.T) {
	coalescer := newTestCoalescer()
	acknowledgement := pureAcknowledgement(1000).packet()
	coalescer.accept(acknowledgement, coalescerStart)

	expectPackets(t, coalescer.drain(), acknowledgement)
	if _, ok := coalescer.nextDeadline(); ok {
		t.Fatal("expected no deadline after draining")
	}
}
