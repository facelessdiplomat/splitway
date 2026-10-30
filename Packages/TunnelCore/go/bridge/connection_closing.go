//go:build !ios

package main

/*
#cgo CFLAGS: -I${SRCDIR}/../../CInterface
#include "TunnelCoreTypes.h"
*/
import "C"

type connectionClosing int32

const (
	closingWrite connectionClosing = C.TCConnectionClosingWrite
	closingRead  connectionClosing = C.TCConnectionClosingRead
	closingBoth  connectionClosing = C.TCConnectionClosingBoth
)
