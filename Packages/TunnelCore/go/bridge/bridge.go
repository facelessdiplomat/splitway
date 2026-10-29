package main

/*
#include <stdlib.h>
*/
import "C"

import "unsafe"

//export tc_version
func tc_version() *C.char {
	return C.CString(version())
}

//export tc_free
func tc_free(pointer unsafe.Pointer) {
	C.free(pointer)
}

func main() {}
