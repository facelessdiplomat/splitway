package main

import (
	"bufio"
	"fmt"
	"io"
	"regexp"
	"slices"
	"strconv"
	"strings"
)

const (
	benchmarkPrefix       = "Benchmark"
	firstMeasurementField = 2
	baselineIterations    = 1
)

var processorSuffix = regexp.MustCompile(`-\d+$`)

type Metric struct {
	Benchmark string
	Unit      string
}

type Summary map[Metric]float64

func ParseSummary(reader io.Reader) (Summary, error) {
	samples := map[Metric][]float64{}
	scanner := bufio.NewScanner(reader)
	for scanner.Scan() {
		fields := strings.Fields(scanner.Text())
		if !isResultLine(fields) {
			continue
		}
		benchmark := processorSuffix.ReplaceAllString(fields[0], "")
		for index := firstMeasurementField; index+1 < len(fields); index += 2 {
			value, err := strconv.ParseFloat(fields[index], 64)
			if err != nil {
				return nil, fmt.Errorf("%s: %q is not a measurement: %w", benchmark, fields[index], err)
			}
			metric := Metric{Benchmark: benchmark, Unit: fields[index+1]}
			samples[metric] = append(samples[metric], value)
		}
	}
	if err := scanner.Err(); err != nil {
		return nil, err
	}
	summary := Summary{}
	for metric, values := range samples {
		summary[metric] = median(values)
	}
	return summary, nil
}

func (summary Summary) Lines() []string {
	metricsByBenchmark := map[string][]Metric{}
	for metric := range summary {
		metricsByBenchmark[metric.Benchmark] = append(metricsByBenchmark[metric.Benchmark], metric)
	}
	benchmarks := make([]string, 0, len(metricsByBenchmark))
	for benchmark := range metricsByBenchmark {
		benchmarks = append(benchmarks, benchmark)
	}
	slices.Sort(benchmarks)
	lines := make([]string, 0, len(benchmarks))
	for _, benchmark := range benchmarks {
		metrics := metricsByBenchmark[benchmark]
		slices.SortFunc(metrics, func(first, second Metric) int { return strings.Compare(first.Unit, second.Unit) })
		fields := []string{benchmark, strconv.Itoa(baselineIterations)}
		for _, metric := range metrics {
			fields = append(fields, strconv.FormatFloat(summary[metric], 'g', -1, 64), metric.Unit)
		}
		lines = append(lines, strings.Join(fields, " "))
	}
	return lines
}

func isResultLine(fields []string) bool {
	if len(fields) <= firstMeasurementField || !strings.HasPrefix(fields[0], benchmarkPrefix) {
		return false
	}
	_, err := strconv.Atoi(fields[1])
	return err == nil
}

func median(values []float64) float64 {
	ordered := slices.Clone(values)
	slices.Sort(ordered)
	middle := len(ordered) / 2
	if len(ordered)%2 == 0 {
		return (ordered[middle-1] + ordered[middle]) / 2
	}
	return ordered[middle]
}
