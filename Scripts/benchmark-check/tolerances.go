package main

import (
	"errors"
	"fmt"
	"slices"
	"strconv"
	"strings"
)

var errMalformedUnitTolerance = errors.New("expected unit=tolerance with a non-negative tolerance")

type Tolerances struct {
	Default float64
	PerUnit map[string]float64
}

func (tolerances Tolerances) For(unit string) float64 {
	if tolerance, found := tolerances.PerUnit[unit]; found {
		return tolerance
	}
	return tolerances.Default
}

func (tolerances *Tolerances) Set(argument string) error {
	unit, text, found := strings.Cut(argument, "=")
	if !found || unit == "" {
		return fmt.Errorf("%q: %w", argument, errMalformedUnitTolerance)
	}
	tolerance, err := strconv.ParseFloat(text, 64)
	if err != nil || tolerance < 0 {
		return fmt.Errorf("%q: %w", argument, errMalformedUnitTolerance)
	}
	tolerances.PerUnit[unit] = tolerance
	return nil
}

func (tolerances *Tolerances) String() string {
	units := make([]string, 0, len(tolerances.PerUnit))
	for unit, tolerance := range tolerances.PerUnit {
		units = append(units, unit+"="+strconv.FormatFloat(tolerance, 'g', -1, 64))
	}
	slices.Sort(units)
	return strings.Join(units, ",")
}
