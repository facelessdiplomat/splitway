package servicerouting

import (
	"net/netip"
	"sync"
)

const reservedLowAddressCount = 256

type fakeAddressPool struct {
	mutex      sync.Mutex
	plan       Plan
	first      netip.Addr
	next       netip.Addr
	fakeByReal map[netip.Addr]netip.Addr
	realByFake map[netip.Addr]netip.Addr
}

func newFakeAddressPool(plan Plan) *fakeAddressPool {
	first := plan.FakeNetwork.Masked().Addr()
	for range reservedLowAddressCount {
		first = first.Next()
	}
	return &fakeAddressPool{
		plan:       plan,
		first:      first,
		next:       first,
		fakeByReal: map[netip.Addr]netip.Addr{},
		realByFake: map[netip.Addr]netip.Addr{},
	}
}

func (pool *fakeAddressPool) fakeFor(real netip.Addr) netip.Addr {
	pool.mutex.Lock()
	defer pool.mutex.Unlock()
	if fake, known := pool.fakeByReal[real]; known {
		return fake
	}
	fake := pool.next
	pool.next = pool.next.Next()
	if !pool.plan.FakeNetwork.Contains(pool.next) {
		pool.next = pool.first
	}
	if previous, taken := pool.realByFake[fake]; taken {
		delete(pool.fakeByReal, previous)
	}
	pool.fakeByReal[real] = fake
	pool.realByFake[fake] = real
	return fake
}

func (pool *fakeAddressPool) realFor(fake netip.Addr) (netip.Addr, bool) {
	pool.mutex.Lock()
	defer pool.mutex.Unlock()
	real, known := pool.realByFake[fake]
	return real, known
}

func (pool *fakeAddressPool) fakeOf(real netip.Addr) (netip.Addr, bool) {
	pool.mutex.Lock()
	defer pool.mutex.Unlock()
	fake, known := pool.fakeByReal[real]
	return fake, known
}
