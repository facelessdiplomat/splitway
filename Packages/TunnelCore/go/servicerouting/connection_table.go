package servicerouting

import (
	"net/netip"
	"time"
)

const noConnection int32 = -1

type recencyList struct {
	newest int32
	oldest int32
}

type connectionTable struct {
	observer   connectionObserver
	slots      []connection
	free       []int32
	byOutbound map[connectionKey]int32
	byInbound  map[connectionKey]int32
	recency    [connectionClassCount]recencyList
}

func newConnectionTable(capacity int, observer connectionObserver) *connectionTable {
	capacity = max(capacity, 1)
	table := &connectionTable{
		observer:   observer,
		slots:      make([]connection, capacity),
		free:       make([]int32, capacity),
		byOutbound: make(map[connectionKey]int32, capacity),
		byInbound:  make(map[connectionKey]int32, capacity),
	}
	for index := range capacity {
		table.free[index] = int32(capacity - 1 - index)
	}
	for class := range table.recency {
		table.recency[class] = recencyList{newest: noConnection, oldest: noConnection}
	}
	return table
}

func (table *connectionTable) outbound(key connectionKey, now time.Duration) (int32, bool) {
	return table.live(table.byOutbound, key, now)
}

func (table *connectionTable) inbound(key connectionKey, now time.Duration) (int32, bool) {
	return table.live(table.byInbound, key, now)
}

func (table *connectionTable) open(outboundKey connectionKey, real netip.Addr, now time.Duration) (int32, bool) {
	inboundKey := connectionKey{
		protocol: outboundKey.protocol,
		local:    outboundKey.local,
		remote:   netip.AddrPortFrom(real, outboundKey.remote.Port()),
	}
	if _, isTaken := table.live(table.byInbound, inboundKey, now); isTaken {
		return noConnection, false
	}
	table.removeExpired(now)
	if len(table.free) == 0 {
		table.remove(table.leastRecentlyUsed())
	}
	position := table.free[len(table.free)-1]
	table.free = table.free[:len(table.free)-1]
	table.slots[position] = connection{
		outboundKey: outboundKey,
		inboundKey:  inboundKey,
		fake:        outboundKey.remote.Addr(),
		real:        real,
		lastSeen:    now,
		newer:       noConnection,
		older:       noConnection,
	}
	table.slots[position].class = table.slots[position].currentClass()
	table.byOutbound[outboundKey] = position
	table.byInbound[inboundKey] = position
	table.pushNewest(position)
	table.observer.connectionOpened(outboundKey.remote.Addr())
	return position, true
}

func (table *connectionTable) observeOutbound(position int32, tcpFlags uint8, now time.Duration) netip.Addr {
	table.slots[position].observeOutbound(tcpFlags)
	table.refresh(position, now)
	return table.slots[position].real
}

func (table *connectionTable) observeInbound(position int32, tcpFlags uint8, now time.Duration) netip.Addr {
	table.slots[position].observeInbound(tcpFlags)
	table.refresh(position, now)
	return table.slots[position].fake
}

func (table *connectionTable) live(index map[connectionKey]int32, key connectionKey, now time.Duration) (int32, bool) {
	position, isFound := index[key]
	if !isFound {
		return noConnection, false
	}
	if table.isExpired(position, now) {
		table.remove(position)
		return noConnection, false
	}
	return position, true
}

func (table *connectionTable) isExpired(position int32, now time.Duration) bool {
	tracked := &table.slots[position]
	return now-tracked.lastSeen > tracked.class.timeout()
}

func (table *connectionTable) removeExpired(now time.Duration) {
	for class := range table.recency {
		for oldest := table.recency[class].oldest; oldest != noConnection && table.isExpired(oldest, now); oldest = table.recency[class].oldest {
			table.remove(oldest)
		}
	}
}

func (table *connectionTable) leastRecentlyUsed() int32 {
	candidate := noConnection
	for _, list := range table.recency {
		if list.oldest != noConnection && (candidate == noConnection || table.slots[list.oldest].lastSeen < table.slots[candidate].lastSeen) {
			candidate = list.oldest
		}
	}
	return candidate
}

func (table *connectionTable) remove(position int32) {
	table.unlink(position)
	delete(table.byOutbound, table.slots[position].outboundKey)
	delete(table.byInbound, table.slots[position].inboundKey)
	table.observer.connectionClosed(table.slots[position].fake)
	table.slots[position] = connection{}
	table.free = append(table.free, position)
}

func (table *connectionTable) refresh(position int32, now time.Duration) {
	table.unlink(position)
	tracked := &table.slots[position]
	tracked.lastSeen = now
	tracked.class = tracked.currentClass()
	table.pushNewest(position)
}

func (table *connectionTable) pushNewest(position int32) {
	tracked := &table.slots[position]
	list := &table.recency[tracked.class]
	tracked.newer, tracked.older = noConnection, list.newest
	if list.newest != noConnection {
		table.slots[list.newest].newer = position
	}
	list.newest = position
	if list.oldest == noConnection {
		list.oldest = position
	}
}

func (table *connectionTable) unlink(position int32) {
	tracked := &table.slots[position]
	list := &table.recency[tracked.class]
	if tracked.newer != noConnection {
		table.slots[tracked.newer].older = tracked.older
	} else {
		list.newest = tracked.older
	}
	if tracked.older != noConnection {
		table.slots[tracked.older].newer = tracked.newer
	} else {
		list.oldest = tracked.newer
	}
	tracked.newer, tracked.older = noConnection, noConnection
}
