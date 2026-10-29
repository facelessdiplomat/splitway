package main

import (
	"regexp"
	"testing"
)

func TestVersionFollowsSemanticVersioning(t *testing.T) {
	semanticVersion := regexp.MustCompile(`^\d+\.\d+\.\d+$`)

	if reported := version(); !semanticVersion.MatchString(reported) {
		t.Fatalf("expected a semantic version, got %q", reported)
	}
}
