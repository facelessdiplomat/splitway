package usernet

import (
	"testing"
	"time"
)

func TestCreditWindowWaitsForAGrant(t *testing.T) {
	window := newCreditWindow()
	window.spend(1)
	result := make(chan bool, 1)

	go func() { result <- window.awaitCredit() }()
	select {
	case <-result:
		t.Fatal("waiting ended without credit")
	default:
	}
	window.grant(2)

	select {
	case hasCredit := <-result:
		if !hasCredit {
			t.Fatal("expected credit after the grant")
		}
	case <-time.After(deliveryTimeout):
		t.Fatal("waiting did not end after the grant")
	}
}

func TestCreditWindowReleasesWaitersWhenClosed(t *testing.T) {
	window := newCreditWindow()
	result := make(chan bool, 1)

	go func() { result <- window.awaitCredit() }()
	window.close()

	select {
	case hasCredit := <-result:
		if hasCredit {
			t.Fatal("expected no credit from a closed window")
		}
	case <-time.After(deliveryTimeout):
		t.Fatal("waiting did not end after close")
	}
}
