package testpeer

import (
	"io"
	"net"
	"net/netip"

	"golang.org/x/net/dns/dnsmessage"
	"golang.zx2c4.com/wireguard/tun/netstack"
)

const (
	largestDatagramByteCount = 65535
	answerTimeToLive         = 60
)

type servers struct {
	closers []io.Closer
}

func startServers(stack *netstack.Net) (*servers, error) {
	running := &servers{}
	streams := map[uint16]func(net.Conn){EchoPort: echo, DiscardPort: discard}
	for port, handle := range streams {
		listener, err := stack.ListenTCPAddrPort(netip.AddrPortFrom(ServerAddress, port))
		if err != nil {
			running.stop()
			return nil, err
		}
		running.closers = append(running.closers, listener)
		go serveStreams(listener, handle)
	}
	datagrams := map[uint16]func([]byte) ([]byte, bool){EchoPort: echoDatagram, DNSPort: answerQuery}
	for port, respond := range datagrams {
		socket, err := stack.ListenUDPAddrPort(netip.AddrPortFrom(ServerAddress, port))
		if err != nil {
			running.stop()
			return nil, err
		}
		running.closers = append(running.closers, socket)
		go serveDatagrams(socket, respond)
	}
	return running, nil
}

func (running *servers) stop() {
	for _, closer := range running.closers {
		closer.Close()
	}
}

func serveStreams(listener net.Listener, handle func(net.Conn)) {
	for {
		connection, err := listener.Accept()
		if err != nil {
			return
		}
		go handle(connection)
	}
}

func echo(connection net.Conn) {
	defer connection.Close()
	if _, err := io.Copy(connection, connection); err != nil {
		return
	}
	if halves, ok := connection.(interface{ CloseWrite() error }); ok {
		halves.CloseWrite()
	}
}

func discard(connection net.Conn) {
	defer connection.Close()
	io.Copy(io.Discard, connection)
}

func serveDatagrams(socket net.PacketConn, respond func([]byte) ([]byte, bool)) {
	buffer := make([]byte, largestDatagramByteCount)
	for {
		byteCount, sender, err := socket.ReadFrom(buffer)
		if err != nil {
			return
		}
		if response, ok := respond(buffer[:byteCount]); ok {
			socket.WriteTo(response, sender)
		}
	}
}

func echoDatagram(datagram []byte) ([]byte, bool) {
	return datagram, true
}

func answerQuery(query []byte) ([]byte, bool) {
	var parser dnsmessage.Parser
	header, err := parser.Start(query)
	if err != nil {
		return nil, false
	}
	question, err := parser.Question()
	if err != nil {
		return nil, false
	}
	builder := dnsmessage.NewBuilder(nil, dnsmessage.Header{ID: header.ID, Response: true, RecursionAvailable: true})
	builder.StartQuestions()
	builder.Question(question)
	builder.StartAnswers()
	if question.Type == dnsmessage.TypeA && question.Name.String() == Hostname+"." {
		resource := dnsmessage.ResourceHeader{Name: question.Name, Class: dnsmessage.ClassINET, TTL: answerTimeToLive}
		builder.AResource(resource, dnsmessage.AResource{A: ServerAddress.As4()})
	}
	response, err := builder.Finish()
	return response, err == nil
}
