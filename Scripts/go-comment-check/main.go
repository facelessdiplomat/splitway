package main

import (
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
	"strings"
)

const (
	exitCodeViolationsFound = 1
	exitCodeUsageError      = 2
)

func main() {
	roots := os.Args[1:]
	if len(roots) == 0 {
		fmt.Fprintln(os.Stderr, "usage: go-comment-check <directory>...")
		os.Exit(exitCodeUsageError)
	}

	violations, err := checkDirectories(roots)
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(exitCodeUsageError)
	}

	for _, violation := range violations {
		fmt.Println(violation)
	}
	if len(violations) > 0 {
		os.Exit(exitCodeViolationsFound)
	}
}

func checkDirectories(roots []string) ([]Violation, error) {
	var violations []Violation
	for _, root := range roots {
		walkErr := filepath.WalkDir(root, func(path string, entry fs.DirEntry, err error) error {
			if err != nil {
				return err
			}
			if entry.IsDir() {
				if path != root && isSkippedDirectory(entry.Name()) {
					return filepath.SkipDir
				}
				return nil
			}
			if filepath.Ext(path) != ".go" {
				return nil
			}
			found, err := checkFile(path)
			violations = append(violations, found...)
			return err
		})
		if walkErr != nil {
			return nil, walkErr
		}
	}
	return violations, nil
}

func checkFile(path string) ([]Violation, error) {
	source, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}
	return FindForbiddenComments(path, source)
}

func isSkippedDirectory(name string) bool {
	return name == "testdata" || name == "vendor" || strings.HasPrefix(name, ".")
}
