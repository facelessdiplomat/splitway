package main

import (
	"cmp"
	"slices"
	"strings"
)

const rateUnitSuffix = "/s"

type Comparison struct {
	Metric   Metric
	Baseline float64
	Current  float64
	Found    bool
}

func Compare(baseline, current Summary) []Comparison {
	comparisons := make([]Comparison, 0, len(baseline))
	for metric, expected := range baseline {
		measured, found := current[metric]
		comparisons = append(comparisons, Comparison{Metric: metric, Baseline: expected, Current: measured, Found: found})
	}
	slices.SortFunc(comparisons, func(first, second Comparison) int {
		return cmp.Or(
			strings.Compare(first.Metric.Benchmark, second.Metric.Benchmark),
			strings.Compare(first.Metric.Unit, second.Metric.Unit),
		)
	})
	return comparisons
}

func (comparison Comparison) Regressed(tolerance float64) bool {
	if !comparison.Found {
		return true
	}
	if isRate(comparison.Metric.Unit) {
		return comparison.Current < comparison.Baseline*(1-tolerance)
	}
	return comparison.Current > comparison.Baseline*(1+tolerance)
}

func (comparison Comparison) Change() float64 {
	if comparison.Baseline == 0 {
		return 0
	}
	return (comparison.Current - comparison.Baseline) / comparison.Baseline
}

func isRate(unit string) bool {
	return strings.HasSuffix(unit, rateUnitSuffix)
}
