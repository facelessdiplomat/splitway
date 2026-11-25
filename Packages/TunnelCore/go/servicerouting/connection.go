package servicerouting

import (
	"net/netip"
	"time"
)

type connectionKey struct {
	protocol uint8
	local    netip.AddrPort
	remote   netip.AddrPort
}

type connection struct {
	outboundKey        connectionKey
	inboundKey         connectionKey
	fake               netip.Addr
	real               netip.Addr
	lastSeen           time.Duration
	class              connectionClass
	isAnswered         bool
	isFinishedByLocal  bool
	isFinishedByRemote bool
	isReset            bool
	newer              int32
	older              int32
}

func (tracked *connection) observeOutbound(tcpFlags uint8) {
	if tracked.outboundKey.protocol != protocolTCP {
		return
	}
	if tcpFlags&(tcpFlagSYN|tcpFlagACK) == tcpFlagSYN && tracked.isClosing() {
		tracked.isAnswered, tracked.isFinishedByLocal, tracked.isFinishedByRemote, tracked.isReset = false, false, false, false
	}
	tracked.isFinishedByLocal = tracked.isFinishedByLocal || tcpFlags&tcpFlagFIN != 0
	tracked.isReset = tracked.isReset || tcpFlags&tcpFlagRST != 0
}

func (tracked *connection) observeInbound(tcpFlags uint8) {
	tracked.isAnswered = true
	if tracked.outboundKey.protocol != protocolTCP {
		return
	}
	tracked.isFinishedByRemote = tracked.isFinishedByRemote || tcpFlags&tcpFlagFIN != 0
	tracked.isReset = tracked.isReset || tcpFlags&tcpFlagRST != 0
}

func (tracked *connection) isClosing() bool {
	return tracked.isReset || (tracked.isFinishedByLocal && tracked.isFinishedByRemote)
}

func (tracked *connection) currentClass() connectionClass {
	switch {
	case tracked.outboundKey.protocol != protocolTCP:
		return udpMapping
	case !tracked.isAnswered || tracked.isClosing():
		return transitoryTCPConnection
	}
	return establishedTCPConnection
}
