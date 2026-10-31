package main

import (
	"flag"
	"fmt"
	"os"
	"strings"
)

const (
	exitCodeRegression = 1
	exitCodeUsageError = 2
	defaultTolerance   = 0.10
	baselineFileMode   = 0o644
	percent            = 100
)

func main() {
	baselinePath := flag.String("baseline", "", "file with the baseline summary")
	writesBaseline := flag.Bool("write", false, "write the measured summary as the new baseline")
	tolerances := Tolerances{PerUnit: map[string]float64{}}
	flag.Float64Var(&tolerances.Default, "tolerance", defaultTolerance, "allowed relative regression")
	flag.Var(&tolerances, "unit-tolerance", "allowed relative regression of one unit, as unit=tolerance")
	flag.Parse()
	if *baselinePath == "" {
		fmt.Fprintln(os.Stderr,
			"usage: go test -bench ... | benchmark-check -baseline <file> [-write] [-tolerance 0.10] [-unit-tolerance unit=0.35]")
		os.Exit(exitCodeUsageError)
	}

	current, err := ParseSummary(os.Stdin)
	if err != nil {
		fail(err)
	}
	if len(current) == 0 {
		fail(fmt.Errorf("no benchmark results on standard input"))
	}
	if *writesBaseline {
		lines := strings.Join(current.Lines(), "\n") + "\n"
		if err := os.WriteFile(*baselinePath, []byte(lines), baselineFileMode); err != nil {
			fail(err)
		}
		fmt.Printf("baseline written to %s\n", *baselinePath)
		return
	}

	baselineFile, err := os.Open(*baselinePath)
	if err != nil {
		fail(err)
	}
	defer baselineFile.Close()
	baseline, err := ParseSummary(baselineFile)
	if err != nil {
		fail(err)
	}
	if regressions := report(baseline, current, tolerances); regressions > 0 {
		fmt.Printf("%d metrics regressed beyond their tolerance\n", regressions)
		os.Exit(exitCodeRegression)
	}
}

func report(baseline, current Summary, tolerances Tolerances) int {
	regressions := 0
	for _, comparison := range Compare(baseline, current) {
		verdict := "ok"
		if comparison.Regressed(tolerances.For(comparison.Metric.Unit)) {
			verdict = "REGRESSION"
			regressions++
		}
		if !comparison.Found {
			fmt.Printf("%-36s %-14s missing %s\n", comparison.Metric.Benchmark, comparison.Metric.Unit, verdict)
			continue
		}
		fmt.Printf("%-36s %-14s baseline %-10.4g current %-10.4g change %+6.1f%% %s\n",
			comparison.Metric.Benchmark, comparison.Metric.Unit,
			comparison.Baseline, comparison.Current, comparison.Change()*percent, verdict)
	}
	for metric, value := range current {
		if _, known := baseline[metric]; !known {
			fmt.Printf("%-36s %-14s new %-10.4g\n", metric.Benchmark, metric.Unit, value)
		}
	}
	return regressions
}

func fail(err error) {
	fmt.Fprintln(os.Stderr, err)
	os.Exit(exitCodeUsageError)
}
