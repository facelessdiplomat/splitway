package main

import "sync"

const firstHandle int32 = 1

type handleTable[Value any] struct {
	mutex      sync.Mutex
	values     map[int32]Value
	lastHandle int32
}

func newHandleTable[Value any]() *handleTable[Value] {
	return &handleTable[Value]{values: make(map[int32]Value)}
}

func (table *handleTable[Value]) add(value Value) int32 {
	table.mutex.Lock()
	defer table.mutex.Unlock()
	handle := table.nextFreeHandle()
	table.values[handle] = value
	return handle
}

func (table *handleTable[Value]) value(handle int32) (Value, bool) {
	table.mutex.Lock()
	defer table.mutex.Unlock()
	value, found := table.values[handle]
	return value, found
}

func (table *handleTable[Value]) remove(handle int32) (Value, bool) {
	table.mutex.Lock()
	defer table.mutex.Unlock()
	value, found := table.values[handle]
	delete(table.values, handle)
	return value, found
}

func (table *handleTable[Value]) nextFreeHandle() int32 {
	for {
		table.lastHandle++
		if table.lastHandle < firstHandle {
			table.lastHandle = firstHandle
		}
		if _, taken := table.values[table.lastHandle]; !taken {
			return table.lastHandle
		}
	}
}
