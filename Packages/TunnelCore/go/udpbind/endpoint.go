package udpbind

import "net/netip"

type Endpoint struct {
	destination netip.AddrPort
}

func (endpoint *Endpoint) ClearSrc() {}

func (endpoint *Endpoint) SrcToString() string {
	return ""
}

func (endpoint *Endpoint) DstToString() string {
	return endpoint.destination.String()
}

func (endpoint *Endpoint) DstToBytes() []byte {
	encoded, _ := endpoint.destination.MarshalBinary()
	return encoded
}

func (endpoint *Endpoint) DstIP() netip.Addr {
	return endpoint.destination.Addr()
}

func (endpoint *Endpoint) SrcIP() netip.Addr {
	return netip.Addr{}
}
