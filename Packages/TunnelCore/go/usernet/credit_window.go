package usernet

import "sync"

type creditWindow struct {
	mutex     sync.Mutex
	changed   *sync.Cond
	available int
	isClosed  bool
}

func newCreditWindow() *creditWindow {
	window := &creditWindow{}
	window.changed = sync.NewCond(&window.mutex)
	return window
}

func (window *creditWindow) awaitCredit() bool {
	window.mutex.Lock()
	defer window.mutex.Unlock()
	for window.available <= 0 && !window.isClosed {
		window.changed.Wait()
	}
	return !window.isClosed
}

func (window *creditWindow) spend(byteCount int) {
	window.mutex.Lock()
	defer window.mutex.Unlock()
	window.available -= byteCount
}

func (window *creditWindow) grant(byteCount int) {
	window.mutex.Lock()
	defer window.mutex.Unlock()
	window.available += byteCount
	window.changed.Broadcast()
}

func (window *creditWindow) close() {
	window.mutex.Lock()
	defer window.mutex.Unlock()
	window.isClosed = true
	window.changed.Broadcast()
}
