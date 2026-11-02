package udpbind

import (
	"context"
	"errors"
	"net"
	"net/netip"
	"strconv"
	"sync"
	"syscall"

	"golang.org/x/sys/unix"
	"golang.zx2c4.com/wireguard/conn"
)

const (
	socketBufferSize      = 7 << 20
	maximumPortAttempts   = 100
	anyPort               = 0
	datagramsPerOperation = 1
)

type Bind struct {
	mutex sync.Mutex
	ipv4  *net.UDPConn
	ipv6  *net.UDPConn
}

func New() *Bind {
	return &Bind{}
}

func (bind *Bind) Open(requestedPort uint16) ([]conn.ReceiveFunc, uint16, error) {
	bind.mutex.Lock()
	defer bind.mutex.Unlock()
	if bind.ipv4 != nil || bind.ipv6 != nil {
		return nil, 0, conn.ErrBindAlreadyOpen
	}
	for attempt := 1; ; attempt++ {
		ipv4, ipv6, port, err := listenOnOnePort(int(requestedPort))
		if requestedPort == anyPort && errors.Is(err, syscall.EADDRINUSE) && attempt < maximumPortAttempts {
			continue
		}
		if err != nil {
			return nil, 0, err
		}
		bind.ipv4, bind.ipv6 = ipv4, ipv6
		return receiversFor(ipv4, ipv6), uint16(port), nil
	}
}

func listenOnOnePort(port int) (*net.UDPConn, *net.UDPConn, int, error) {
	ipv4, port, err := listen("udp4", port)
	if err != nil && !errors.Is(err, syscall.EAFNOSUPPORT) {
		return nil, nil, 0, err
	}
	ipv6, ipv6Port, err := listen("udp6", port)
	if err != nil && !errors.Is(err, syscall.EAFNOSUPPORT) {
		closeIfOpen(ipv4)
		return nil, nil, 0, err
	}
	if ipv4 == nil && ipv6 == nil {
		return nil, nil, 0, syscall.EAFNOSUPPORT
	}
	if ipv4 == nil {
		port = ipv6Port
	}
	return ipv4, ipv6, port, nil
}

func listen(network string, port int) (*net.UDPConn, int, error) {
	configuration := net.ListenConfig{Control: enlargeSocketBuffers}
	listener, err := configuration.ListenPacket(context.Background(), network, ":"+strconv.Itoa(port))
	if err != nil {
		return nil, port, err
	}
	connection := listener.(*net.UDPConn)
	return connection, connection.LocalAddr().(*net.UDPAddr).Port, nil
}

func enlargeSocketBuffers(_, _ string, raw syscall.RawConn) error {
	return raw.Control(func(descriptor uintptr) {
		_ = unix.SetsockoptInt(int(descriptor), unix.SOL_SOCKET, unix.SO_RCVBUF, socketBufferSize)
		_ = unix.SetsockoptInt(int(descriptor), unix.SOL_SOCKET, unix.SO_SNDBUF, socketBufferSize)
	})
}

func receiversFor(connections ...*net.UDPConn) []conn.ReceiveFunc {
	var receivers []conn.ReceiveFunc
	for _, connection := range connections {
		if connection != nil {
			receivers = append(receivers, receiver(connection))
		}
	}
	return receivers
}

func receiver(connection *net.UDPConn) conn.ReceiveFunc {
	return func(packets [][]byte, sizes []int, endpoints []conn.Endpoint) (int, error) {
		size, sender, err := connection.ReadFromUDPAddrPort(packets[0])
		if err != nil {
			return 0, err
		}
		sizes[0] = size
		endpoints[0] = &Endpoint{destination: netip.AddrPortFrom(sender.Addr().Unmap(), sender.Port())}
		return datagramsPerOperation, nil
	}
}

func (bind *Bind) Close() error {
	bind.mutex.Lock()
	defer bind.mutex.Unlock()
	err := errors.Join(closeIfOpen(bind.ipv4), closeIfOpen(bind.ipv6))
	bind.ipv4, bind.ipv6 = nil, nil
	return err
}

func closeIfOpen(connection *net.UDPConn) error {
	if connection == nil {
		return nil
	}
	return connection.Close()
}

func (bind *Bind) SetMark(uint32) error {
	return nil
}

func (bind *Bind) Send(packets [][]byte, endpoint conn.Endpoint) error {
	destination, ok := endpoint.(*Endpoint)
	if !ok {
		return conn.ErrWrongEndpointType
	}
	connection := bind.connectionFor(destination.destination.Addr())
	if connection == nil {
		return syscall.EAFNOSUPPORT
	}
	for _, packet := range packets {
		if _, err := connection.WriteToUDPAddrPort(packet, destination.destination); err != nil {
			return err
		}
	}
	return nil
}

func (bind *Bind) connectionFor(address netip.Addr) *net.UDPConn {
	bind.mutex.Lock()
	defer bind.mutex.Unlock()
	if address.Is6() {
		return bind.ipv6
	}
	return bind.ipv4
}

func (bind *Bind) ParseEndpoint(text string) (conn.Endpoint, error) {
	destination, err := netip.ParseAddrPort(text)
	if err != nil {
		return nil, err
	}
	return &Endpoint{destination: destination}, nil
}

func (bind *Bind) BatchSize() int {
	return datagramsPerOperation
}
