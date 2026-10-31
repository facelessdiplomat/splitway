package usernet

import "time"

type heldAcknowledgement struct {
	flow                 tcpFlow
	packet               []byte
	firstAcknowledgement uint32
	acknowledgement      uint32
	deadline             time.Time
}

type acknowledgementCoalescer struct {
	holdDuration   time.Duration
	maximumStretch uint32
	held           []*heldAcknowledgement
}

func newAcknowledgementCoalescer(holdDuration time.Duration, maximumStretch uint32) *acknowledgementCoalescer {
	return &acknowledgementCoalescer{holdDuration: holdDuration, maximumStretch: maximumStretch}
}

func (coalescer *acknowledgementCoalescer) accept(packet []byte, now time.Time) [][]byte {
	segment, isTCP := parseTCPSegment(packet)
	if !isTCP {
		return [][]byte{packet}
	}
	index := coalescer.indexOf(segment.flow)
	if index < 0 {
		if !segment.isPureAcknowledgement {
			return [][]byte{packet}
		}
		coalescer.held = append(coalescer.held, &heldAcknowledgement{
			flow:                 segment.flow,
			packet:               packet,
			firstAcknowledgement: segment.acknowledgement,
			acknowledgement:      segment.acknowledgement,
			deadline:             now.Add(coalescer.holdDuration),
		})
		return nil
	}
	held := coalescer.held[index]
	if !segment.isPureAcknowledgement || !sequenceAfter(segment.acknowledgement, held.acknowledgement) {
		coalescer.remove(index)
		return [][]byte{held.packet, packet}
	}
	if segment.acknowledgement-held.firstAcknowledgement >= coalescer.maximumStretch {
		coalescer.remove(index)
		return [][]byte{packet}
	}
	held.packet = packet
	held.acknowledgement = segment.acknowledgement
	return nil
}

func (coalescer *acknowledgementCoalescer) expire(now time.Time) [][]byte {
	var due [][]byte
	for len(coalescer.held) > 0 && !coalescer.held[0].deadline.After(now) {
		due = append(due, coalescer.held[0].packet)
		coalescer.remove(0)
	}
	return due
}

func (coalescer *acknowledgementCoalescer) nextDeadline() (time.Time, bool) {
	if len(coalescer.held) == 0 {
		return time.Time{}, false
	}
	return coalescer.held[0].deadline, true
}

func (coalescer *acknowledgementCoalescer) drain() [][]byte {
	drained := make([][]byte, 0, len(coalescer.held))
	for _, held := range coalescer.held {
		drained = append(drained, held.packet)
	}
	coalescer.held = nil
	return drained
}

func (coalescer *acknowledgementCoalescer) indexOf(flow tcpFlow) int {
	for index, held := range coalescer.held {
		if held.flow == flow {
			return index
		}
	}
	return -1
}

func (coalescer *acknowledgementCoalescer) remove(index int) {
	coalescer.held = append(coalescer.held[:index], coalescer.held[index+1:]...)
}

func sequenceAfter(later, earlier uint32) bool {
	return int32(later-earlier) > 0
}
