package servicerouting

import (
	"encoding/binary"
	"net/netip"
	"time"
)

const (
	maximumFakeAddresses       = 8192
	reservedFakeAddressCount   = 256
	minimumFakeAddressLifetime = 10 * time.Minute
)

type fakeAddressEntry struct {
	name            string
	fake            netip.Addr
	real            netip.Addr
	lastAnswered    time.Duration
	connectionCount int
}

type fakeAddressFamily struct {
	network  netip.Prefix
	first    netip.Addr
	cursor   netip.Addr
	capacity int
	byName   map[string]*fakeAddressEntry
	byFake   map[netip.Addr]*fakeAddressEntry
}

func newFakeAddressFamily(network netip.Prefix, capacity int) *fakeAddressFamily {
	if !network.IsValid() {
		return nil
	}
	network = network.Masked()
	first := addressAfter(network.Addr(), reservedFakeAddressCount)
	return &fakeAddressFamily{
		network:  network,
		first:    first,
		cursor:   first,
		capacity: max(capacity, 1),
		byName:   make(map[string]*fakeAddressEntry),
		byFake:   make(map[netip.Addr]*fakeAddressEntry),
	}
}

func (family *fakeAddressFamily) fakeFor(name string, real netip.Addr, now time.Duration) (netip.Addr, bool) {
	if entry, isKnown := family.byName[name]; isKnown {
		entry.real, entry.lastAnswered = real, now
		return entry.fake, true
	}
	if len(family.byName) >= family.capacity && !family.forgetStaleName(now) {
		return netip.Addr{}, false
	}
	fake, isFree := family.nextFreeAddress()
	if !isFree {
		if !family.forgetStaleName(now) {
			return netip.Addr{}, false
		}
		if fake, isFree = family.nextFreeAddress(); !isFree {
			return netip.Addr{}, false
		}
	}
	entry := &fakeAddressEntry{name: name, fake: fake, real: real, lastAnswered: now}
	family.byName[name] = entry
	family.byFake[fake] = entry
	return fake, true
}

func (family *fakeAddressFamily) entry(fake netip.Addr) (*fakeAddressEntry, bool) {
	entry, isKnown := family.byFake[fake]
	return entry, isKnown
}

func (family *fakeAddressFamily) nextFreeAddress() (netip.Addr, bool) {
	if !family.network.Contains(family.first) {
		return netip.Addr{}, false
	}
	for range len(family.byFake) + 1 {
		candidate := family.cursor
		family.cursor = family.after(candidate)
		if _, isTaken := family.byFake[candidate]; !isTaken {
			return candidate, true
		}
	}
	return netip.Addr{}, false
}

func (family *fakeAddressFamily) after(address netip.Addr) netip.Addr {
	next := address.Next()
	if !next.IsValid() || !family.network.Contains(next) {
		return family.first
	}
	return next
}

func (family *fakeAddressFamily) forgetStaleName(now time.Duration) bool {
	var oldest *fakeAddressEntry
	for _, entry := range family.byName {
		isStale := entry.connectionCount == 0 && now-entry.lastAnswered >= minimumFakeAddressLifetime
		if isStale && (oldest == nil || entry.lastAnswered < oldest.lastAnswered) {
			oldest = entry
		}
	}
	if oldest == nil {
		return false
	}
	delete(family.byName, oldest.name)
	delete(family.byFake, oldest.fake)
	return true
}

func addressAfter(base netip.Addr, offset uint64) netip.Addr {
	if base.Is4() {
		bytes := base.As4()
		value := binary.BigEndian.Uint32(bytes[:]) + uint32(offset)
		binary.BigEndian.PutUint32(bytes[:], value)
		return netip.AddrFrom4(bytes)
	}
	bytes := base.As16()
	value := binary.BigEndian.Uint64(bytes[8:]) + offset
	binary.BigEndian.PutUint64(bytes[8:], value)
	return netip.AddrFrom16(bytes)
}
