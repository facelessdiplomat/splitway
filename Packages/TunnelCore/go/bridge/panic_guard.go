package main

func guarded(operation func() tunnelStatus) (status tunnelStatus) {
	defer func() {
		if recover() != nil {
			status = statusInternalFailure
		}
	}()
	return operation()
}
