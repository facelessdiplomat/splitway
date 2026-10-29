package main

import (
	"fmt"
	"go/ast"
	"go/parser"
	"go/token"
	"strings"
)

const maximumReportedCommentLength = 80

var allowedDirectivePrefixes = []string{"//go:", "//export "}

type Violation struct {
	Path string
	Line int
	Text string
}

func (violation Violation) String() string {
	return fmt.Sprintf("%s:%d: forbidden comment: %s", violation.Path, violation.Line, violation.Text)
}

func FindForbiddenComments(path string, source []byte) ([]Violation, error) {
	fileSet := token.NewFileSet()
	file, err := parser.ParseFile(fileSet, path, source, parser.ParseComments)
	if err != nil {
		return nil, err
	}

	preambles := cgoPreambles(file)
	var violations []Violation
	for _, group := range file.Comments {
		if preambles[group] {
			continue
		}
		for _, comment := range group.List {
			if isDirective(comment.Text) {
				continue
			}
			violations = append(violations, Violation{
				Path: path,
				Line: fileSet.Position(comment.Pos()).Line,
				Text: summary(comment.Text),
			})
		}
	}
	return violations, nil
}

func cgoPreambles(file *ast.File) map[*ast.CommentGroup]bool {
	preambles := map[*ast.CommentGroup]bool{}
	for _, declaration := range file.Decls {
		importDeclaration, isGenericDeclaration := declaration.(*ast.GenDecl)
		if !isGenericDeclaration || importDeclaration.Tok != token.IMPORT {
			continue
		}
		for _, specification := range importDeclaration.Specs {
			importSpecification, isImport := specification.(*ast.ImportSpec)
			if !isImport || importSpecification.Path.Value != `"C"` {
				continue
			}
			if importDeclaration.Doc != nil {
				preambles[importDeclaration.Doc] = true
			}
			if importSpecification.Doc != nil {
				preambles[importSpecification.Doc] = true
			}
		}
	}
	return preambles
}

func isDirective(comment string) bool {
	for _, prefix := range allowedDirectivePrefixes {
		if strings.HasPrefix(comment, prefix) {
			return true
		}
	}
	return false
}

func summary(comment string) string {
	firstLine, _, _ := strings.Cut(comment, "\n")
	if len(firstLine) > maximumReportedCommentLength {
		return firstLine[:maximumReportedCommentLength] + "…"
	}
	return firstLine
}
