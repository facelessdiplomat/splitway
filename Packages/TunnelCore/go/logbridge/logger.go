package logbridge

import (
	"fmt"

	"golang.zx2c4.com/wireguard/device"
)

type Level int32

const (
	LevelVerbose Level = 0
	LevelError   Level = 1
)

type Sink func(level Level, message string)

func DeviceLogger(sink Sink) *device.Logger {
	return &device.Logger{
		Verbosef: formattingFor(LevelVerbose, sink),
		Errorf:   formattingFor(LevelError, sink),
	}
}

func formattingFor(level Level, sink Sink) func(format string, arguments ...any) {
	return func(format string, arguments ...any) {
		sink(level, fmt.Sprintf(format, arguments...))
	}
}
