package main

import "splitway/tunnelcore/usernet"

var openConnections = newHandleTable[*usernet.Connection]()

func startReceiving(handle int32, receiver usernet.Receiver, buffer []byte, initialCredit int) tunnelStatus {
	connection, found := openConnections.value(handle)
	if !found {
		return statusUnknownHandle
	}
	options := usernet.ReceiveOptions{ReadBuffer: buffer, InitialCredit: initialCredit}
	if err := connection.StartReceiving(receiver, options); err != nil {
		return statusInvalidArgument
	}
	return statusOK
}

func writeToConnection(handle int32, data []byte) (int, tunnelStatus) {
	connection, found := openConnections.value(handle)
	if !found {
		return 0, statusUnknownHandle
	}
	written, err := connection.Write(data)
	if err != nil {
		return written, statusConnectionClosed
	}
	return written, statusOK
}

func grantCredit(handle int32, byteCount int) tunnelStatus {
	connection, found := openConnections.value(handle)
	if !found {
		return statusUnknownHandle
	}
	connection.Grant(byteCount)
	return statusOK
}

func closeConnection(handle int32, closing connectionClosing) tunnelStatus {
	connection, found := openConnections.value(handle)
	if !found {
		return statusUnknownHandle
	}
	switch closing {
	case closingWrite:
		connection.CloseWrite()
	case closingRead:
		connection.CloseRead()
	case closingBoth:
		openConnections.remove(handle)
		connection.Close()
	default:
		return statusInvalidArgument
	}
	return statusOK
}
