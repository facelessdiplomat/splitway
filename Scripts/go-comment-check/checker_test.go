package main

import (
	"os"
	"path/filepath"
	"slices"
	"testing"
)

func TestFindForbiddenCommentsReportsLinesOfForbiddenComments(t *testing.T) {
	testCases := []struct {
		name          string
		source        string
		expectedLines []int
	}{
		{name: "line comment", source: "package sample\n\n// explanation\nvar value = 1\n", expectedLines: []int{3}},
		{name: "block comment", source: "package sample\n\n/* explanation */\nvar value = 1\n", expectedLines: []int{3}},
		{name: "documentation comment", source: "package sample\n\n// Run starts work.\nfunc Run() {}\n", expectedLines: []int{3}},
		{name: "comment inside function", source: "package sample\n\nfunc run() {\n\t// step\n}\n", expectedLines: []int{4}},
		{name: "trailing comment", source: "package sample\n\nvar value = 1 // explanation\n", expectedLines: []int{3}},
		{name: "linter suppression", source: "package sample\n\nvar value = 1 //nolint\n", expectedLines: []int{3}},
		{name: "legacy build constraint", source: "// +build darwin\n\npackage sample\n", expectedLines: []int{1}},
		{name: "build constraint directive", source: "//go:build darwin\n\npackage sample\n", expectedLines: nil},
		{name: "linkname directive", source: "package sample\n\nimport _ \"unsafe\"\n\n//go:linkname now time.now\nfunc now() int64\n", expectedLines: nil},
		{name: "export directive", source: "package main\n\nimport \"C\"\n\n//export tc_version\nfunc tc_version() {}\n", expectedLines: nil},
		{name: "cgo preamble", source: "package main\n\n/*\n#include <stdlib.h>\n*/\nimport \"C\"\n", expectedLines: nil},
		{name: "comment after cgo preamble", source: "package main\n\n/*\n#include <stdlib.h>\n*/\nimport \"C\"\n\n// explanation\nvar value = 1\n", expectedLines: []int{8}},
		{name: "double slash inside string", source: "package sample\n\nvar address = \"https://example.com\"\n", expectedLines: nil},
	}

	for _, testCase := range testCases {
		t.Run(testCase.name, func(t *testing.T) {
			violations, err := FindForbiddenComments("sample.go", []byte(testCase.source))
			if err != nil {
				t.Fatalf("unexpected parse error: %v", err)
			}

			if actualLines := violationLines(violations); !slices.Equal(actualLines, testCase.expectedLines) {
				t.Fatalf("expected violations on lines %v, got %v", testCase.expectedLines, actualLines)
			}
		})
	}
}

func TestFindForbiddenCommentsRejectsInvalidSource(t *testing.T) {
	if _, err := FindForbiddenComments("broken.go", []byte("package")); err == nil {
		t.Fatal("expected a parse error for invalid source")
	}
}

func TestCheckDirectoriesSkipsTestdataAndHiddenDirectories(t *testing.T) {
	root := t.TempDir()
	writeSource(t, filepath.Join(root, "visible.go"), "package sample\n\n// explanation\nvar value = 1\n")
	writeSource(t, filepath.Join(root, "testdata", "fixture.go"), "package fixture\n\n// explanation\nvar value = 1\n")
	writeSource(t, filepath.Join(root, ".cache", "cached.go"), "package cached\n\n// explanation\nvar value = 1\n")

	violations, err := checkDirectories([]string{root})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if len(violations) != 1 || filepath.Base(violations[0].Path) != "visible.go" {
		t.Fatalf("expected a single violation in visible.go, got %v", violations)
	}
}

func violationLines(violations []Violation) []int {
	lines := make([]int, 0, len(violations))
	for _, violation := range violations {
		lines = append(lines, violation.Line)
	}
	return lines
}

func writeSource(t *testing.T, path string, source string) {
	t.Helper()
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		t.Fatalf("cannot create directory: %v", err)
	}
	if err := os.WriteFile(path, []byte(source), 0o644); err != nil {
		t.Fatalf("cannot write source: %v", err)
	}
}
