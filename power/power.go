// Package power provides a library to read SysFS info on battery state.
package power

import (
	"fmt"
	"io/ioutil"
	"path/filepath"
	"strconv"
	"strings"
)

// Glob for SysFS paths, under which energy_now, energy_full and state files are assumed to exist.
var path = "/sys/class/power_supply/BAT*/"

const (
	Empty State = iota
	Full
	Charging
	Unknown
)

var statees = [...]string{
	"Empty",
	"Full",
	"Charging",
	"Discharging",
	"Unknown",
}

func GetState(s string) (State, error) {
	for i, name := range statees {
		if strings.EqualFold(name, s) {
			return State(i), nil
		}
	}
	return State(0), fmt.Errorf("no state named %v", s)
}

func (s State) String() string {
	return statees[s]
}

type State int

type Battery struct {
	Current float32 // current charge, [0.0, 1.0]
	State   State
}

// String forms a pretty string representation of the battery.
func (b Battery) String() string {
	return fmt.Sprintf("%-12s (%.2f%%)", b.State, 100*b.Current)
}

// readGlob reads the file contents at a glob and returns their contents.
func readGlob(glob string) ([]string, error) {
	paths, err := filepath.Glob(glob)
	if err != nil {
		return []string{}, err
	}
	result := make([]string, len(paths))
	for i, p := range paths {
		bytes, err := ioutil.ReadFile(p)
		if err != nil {
			return []string{}, err
		}
		result[i] = strings.TrimRight(string(bytes), "\n")
	}
	return result, nil
}

// parseCharge parses the charge percentage from string values.
func parseCharge(p, f string) (float32, error) {
	pi, err := strconv.ParseInt(p, 10, 0)
	if err != nil {
		return 0.0, err
	}
	fi, err := strconv.ParseInt(f, 10, 0)
	if err != nil {
		return 0.0, err
	}
	return float32(pi) / float32(fi), nil
}

// Get reads SysFS paths to find state of batteries.
func Get() ([]Battery, error) {
	pwr, err := readGlob(path + "energy_now")
	if err != nil {
		return []Battery{}, fmt.Errorf("couldn't read SysFS %s/energy_now: %v\n", path, err)
	}
	state, err := readGlob(path + "status")
	if err != nil {
		return []Battery{}, fmt.Errorf("couldn't read SysFS %s/status: %v\n", path, err)
	}
	full, err := readGlob(path + "energy_full")
	if err != nil {
		return []Battery{}, fmt.Errorf("couldn't read SysFS %s/energy_full: %v\n", path, err)
	}
	if len(pwr) != len(state) || len(state) != len(full) {
		return []Battery{}, fmt.Errorf("%d power_now files, %d state files but %d energy_full files; expected all to exist\n", len(pwr), len(state), len(full))
	}
	result := make([]Battery, len(pwr))
	for i := range state {
		c, err := parseCharge(pwr[i], full[i])
		if err != nil {
			return []Battery{}, fmt.Errorf("couldn't parse battery charge: %v\n", err)
		}
		state, err := GetState(state[i])
		if err != nil {
			return []Battery{}, err
		}
		result[i] = Battery{
			Current: c,
			State:   state,
		}
	}
	return result, nil
}
