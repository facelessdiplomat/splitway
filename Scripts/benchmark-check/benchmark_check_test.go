package main

import (
	"strings"
	"testing"
)

const sampleOutput = `goos: darwin
goarch: arm64
pkg: splitway/tunnelcore/usernet
BenchmarkUploadThroughTheTunnel-14      	    4977	    686587 ns/op	  95.45 MB/s
BenchmarkUploadThroughTheTunnel-14      	    7020	    678085 ns/op	  96.65 MB/s
BenchmarkUploadThroughTheTunnel-14      	    6068	    681266 ns/op	  96.20 MB/s
BenchmarkDownloadThroughTheTunnel-14    	    3579	    664238 ns/op	  98.66 MB/s	         0.6052 acks/segment
PASS
ok  	splitway/tunnelcore/usernet	19.676s
`

func TestParseSummaryTakesTheMedianOfRepeatedRuns(t *testing.T) {
	summary, err := ParseSummary(strings.NewReader(sampleOutput))
	if err != nil {
		t.Fatal(err)
	}

	if rate := summary[Metric{Benchmark: "BenchmarkUploadThroughTheTunnel", Unit: "MB/s"}]; rate != 96.20 {
		t.Fatalf("expected the median rate 96.20, got %v", rate)
	}
}

func TestParseSummaryKeepsEveryReportedUnit(t *testing.T) {
	summary, err := ParseSummary(strings.NewReader(sampleOutput))
	if err != nil {
		t.Fatal(err)
	}

	acknowledgements := summary[Metric{Benchmark: "BenchmarkDownloadThroughTheTunnel", Unit: "acks/segment"}]
	if acknowledgements != 0.6052 {
		t.Fatalf("expected 0.6052 acks/segment, got %v", acknowledgements)
	}
	if len(summary) != 5 {
		t.Fatalf("expected 5 metrics without the processor suffix in the names, got %v", summary)
	}
}

func TestParseSummaryRejectsAMalformedValue(t *testing.T) {
	_, err := ParseSummary(strings.NewReader("BenchmarkUpload-14 10 fast ns/op\n"))

	if err == nil {
		t.Fatal("expected an error for a value that is not a number")
	}
}

func TestSummaryLinesReadBackAsTheSameSummary(t *testing.T) {
	summary, err := ParseSummary(strings.NewReader(sampleOutput))
	if err != nil {
		t.Fatal(err)
	}

	reread, err := ParseSummary(strings.NewReader(strings.Join(summary.Lines(), "\n")))
	if err != nil {
		t.Fatal(err)
	}
	if len(reread) != len(summary) {
		t.Fatalf("expected %d metrics, got %d", len(summary), len(reread))
	}
	for metric, value := range summary {
		if reread[metric] != value {
			t.Fatalf("expected %v for %v, got %v", value, metric, reread[metric])
		}
	}
}

func TestComparisonRegressesBeyondTheTolerance(t *testing.T) {
	testCases := []struct {
		name      string
		unit      string
		baseline  float64
		current   float64
		regressed bool
	}{
		{name: "slower rate", unit: "MB/s", baseline: 100, current: 89, regressed: true},
		{name: "slightly slower rate", unit: "MB/s", baseline: 100, current: 91, regressed: false},
		{name: "faster rate", unit: "MB/s", baseline: 100, current: 150, regressed: false},
		{name: "higher time per operation", unit: "ns/op", baseline: 1000, current: 1111, regressed: true},
		{name: "slightly higher time per operation", unit: "ns/op", baseline: 1000, current: 1090, regressed: false},
		{name: "more acknowledgements", unit: "acks/segment", baseline: 0.20, current: 0.25, regressed: true},
		{name: "fewer acknowledgements", unit: "acks/segment", baseline: 0.60, current: 0.20, regressed: false},
	}

	for _, testCase := range testCases {
		t.Run(testCase.name, func(t *testing.T) {
			metric := Metric{Benchmark: "BenchmarkSample", Unit: testCase.unit}
			comparisons := Compare(Summary{metric: testCase.baseline}, Summary{metric: testCase.current})

			if len(comparisons) != 1 || comparisons[0].Regressed(0.10) != testCase.regressed {
				t.Fatalf("expected regressed=%v, got %+v", testCase.regressed, comparisons)
			}
		})
	}
}

func TestComparisonRegressesWhenABenchmarkIsMissing(t *testing.T) {
	metric := Metric{Benchmark: "BenchmarkSample", Unit: "MB/s"}

	comparisons := Compare(Summary{metric: 100}, Summary{})

	if len(comparisons) != 1 || comparisons[0].Found || !comparisons[0].Regressed(0.10) {
		t.Fatalf("expected a missing benchmark to regress, got %+v", comparisons)
	}
}

func TestTolerancesPreferTheToleranceOfTheUnit(t *testing.T) {
	tolerances := Tolerances{Default: 0.10, PerUnit: map[string]float64{"acks/segment": 0.35}}

	if tolerance := tolerances.For("acks/segment"); tolerance != 0.35 {
		t.Fatalf("expected the tolerance of the unit, got %v", tolerance)
	}
	if tolerance := tolerances.For("MB/s"); tolerance != 0.10 {
		t.Fatalf("expected the default tolerance, got %v", tolerance)
	}
}

func TestUnitToleranceFlagReadsUnitAndValue(t *testing.T) {
	testCases := []struct {
		name     string
		argument string
		valid    bool
	}{
		{name: "unit and value", argument: "acks/segment=0.35", valid: true},
		{name: "missing value", argument: "acks/segment", valid: false},
		{name: "value that is not a number", argument: "acks/segment=high", valid: false},
		{name: "negative value", argument: "acks/segment=-0.1", valid: false},
		{name: "missing unit", argument: "=0.35", valid: false},
	}

	for _, testCase := range testCases {
		t.Run(testCase.name, func(t *testing.T) {
			tolerances := Tolerances{Default: 0.10, PerUnit: map[string]float64{}}

			err := tolerances.Set(testCase.argument)

			if (err == nil) != testCase.valid {
				t.Fatalf("expected valid=%v, got error %v", testCase.valid, err)
			}
			if testCase.valid && tolerances.For("acks/segment") != 0.35 {
				t.Fatalf("expected 0.35 for acks/segment, got %v", tolerances.For("acks/segment"))
			}
		})
	}
}
