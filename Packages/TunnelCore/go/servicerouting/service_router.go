package servicerouting

import "time"

type serviceRouter struct {
	plan        Plan
	interceptor *dnsInterceptor
	translator  *addressTranslator
}

func newServiceRouter(plan Plan, clock func() time.Time) *serviceRouter {
	pool := newFakeAddressPool(plan.fakeNetworks(), clock, maximumFakeAddresses)
	return &serviceRouter{
		plan:        plan,
		interceptor: newDNSInterceptor(plan.VirtualDNS, plan.UpstreamDNS, pool, clock),
		translator:  newAddressTranslator(plan.fakePrefixes(), pool, clock, maximumTrackedConnections),
	}
}

func (router *serviceRouter) outbound(packet []byte) bool {
	layout, isParsed := layoutOf(packet)
	if !isParsed {
		return true
	}
	if isHandled, isForwarded := router.interceptor.outbound(packet, layout); isHandled {
		return isForwarded
	}
	return router.translator.translateOutbound(packet, layout)
}

func (router *serviceRouter) inbound(packet []byte) (replacement []byte, isDelivered bool) {
	layout, isParsed := layoutOf(packet)
	if !isParsed {
		return nil, true
	}
	if answer, isHandled := router.interceptor.inbound(packet, layout); isHandled {
		return answer, answer != nil
	}
	router.translator.translateInbound(packet, layout)
	return nil, true
}
