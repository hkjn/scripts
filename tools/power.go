// Simple tools to read SysFS info on battery status.
package main

import (
	"fmt"
	"io/ioutil"
	"log"
	"path/filepath"
	"strconv"
	"strings"
)

var path = "/sys/class/power_supply/BAT*/"

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

func getBatteries() ([]battery, error) {
	pwr, err := readGlob(path + "energy_now")
	if err != nil {
		return []battery{}, fmt.Errorf("couldn't read SysFS %s/power_now: %v\n", path, err)
	}
	status, err := readGlob(path + "status")
	if err != nil {
		return []battery{}, fmt.Errorf("couldn't read SysFS %s/status: %v\n", path, err)
	}
	full, err := readGlob(path + "energy_full")
	if err != nil {
		return []battery{}, fmt.Errorf("couldn't read SysFS %s/energy_full: %v\n", path, err)
	}
	if len(pwr) != len(status) || len(status) != len(full) {
		return []battery{}, fmt.Errorf("%d power_now files, %d status files but %d energy_full files; expected all to exist\n", len(pwr), len(status), len(full))
	}
	result := make([]battery, len(pwr))
	for i := range status {
		c, err := parseCharge(pwr[i], full[i])
		if err != nil {
			return []battery{}, fmt.Errorf("couldn't parse battery charge: %v\n", err)
		}
		result[i] = battery{current: c, status: status[i]}
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

type battery struct {
	current float32
	status  string
}

func main() {
	bat, err := getBatteries()
	if err != nil {
		log.Fatalf("failed to get battery info: %v\n", err)
	}
	for i, b := range bat {
		log.Printf("[Battery %d]: %+v\n", i, b)
	}
}
