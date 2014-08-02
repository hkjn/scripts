// Package power provides a library to read SysFS info on battery state.
package power

import (
	"errors"
	"fmt"
	"io/ioutil"
	"path/filepath"
	"strconv"
	"strings"
)

var (
	BasePath  = "/sys/class/power_supply/" // base SysFS path, under which battery info is assumed to exist.
	ErrNoFile = errors.New("no such file or directory")
)

// Charge is the current charge of a battery.
type Charge float32

// Battery represents information about a battery.
type Battery struct {
	Charge Charge // current charge, [0.0, 1.0]
	State  State
}

func (c Charge) String() string {
	if c < 0.1 {
		return "empty"
	} else if c < 0.3 {
		return "caution"
	} else if c < 0.5 {
		return "low"
	} else if c < 0.9 {
		return "good"
	} else {
		return "full"
	}
}

// sysFile is a SysFS file.
type sysFile string

// sysInfo holds the contents read from SysFS.
type sysInfo map[sysFile]string

// sysFiles are the SysFS files to read.
var sysFiles = []sysFile{
	"energy_now",
	"energy_full",
	"status",
}

// State is the state of a battery.
type State int

const (
	Empty State = iota
	Full
	Charging
	Discharging
	Unknown
)

var states = [...]string{
	"Empty",
	"Full",
	"Charging",
	"Discharging",
	"Unknown",
}

// String returns the name of the state.
func (s State) String() string {
	return states[s]
}

// parse parses the state from the raw string.
func (s *State) parse(in string) error {
	for i, name := range states {
		if strings.EqualFold(name, in) {
			*s = State(i)
			return nil
		}
	}
	return fmt.Errorf("no state named %v", s)
}

// String returns a descriptive representation of the battery.
func (b Battery) String() string {
	return fmt.Sprintf("%-12s (%.2f%%)", b.State, 100*b.Charge)
}

// Desc describes the battery, in a way compatible to GTK icon names.
func (b Battery) Desc() string {
	charge := b.Charge.String()
	if b.State == Charging {
		return fmt.Sprintf("battery-%s-%s", charge, strings.ToLower(b.State.String()))
	} else {
		return fmt.Sprintf("battery-%s", charge)
	}
}

// read reads the SysFS file.
func (s *sysFile) read(path string) (string, error) {
	path = filepath.Join(path, string(*s))
	bytes, err := ioutil.ReadFile(path)
	if err != nil {
		if strings.HasSuffix(err.Error(), ErrNoFile.Error()) {
			return "", ErrNoFile
		}
		return "", fmt.Errorf("couldn't read from SysFS: %v\n", err)
	}
	return strings.TrimRight(string(bytes), "\n"), nil
}

// read reads a single SysFS file holding state of a battery.
func (s sysInfo) read(path string) error {
	for _, f := range sysFiles {
		c, err := f.read(path)
		if err != nil {
			return err
		}
		s[f] = c
	}
	return nil
}

// parseCharge parses the charge percentage from string values.
func parseCharge(p, f string) (Charge, error) {
	pi, err := strconv.ParseInt(p, 10, 0)
	if err != nil {
		return Charge(0.0), err
	}
	fi, err := strconv.ParseInt(f, 10, 0)
	if err != nil {
		return Charge(0.0), err
	}
	return Charge(float32(pi) / float32(fi)), nil
}

// GetNumber reads SysFS to find state of the battery with given index.
func GetNumber(i int) (Battery, error) {
	si := make(sysInfo)
	err := si.read(filepath.Join(BasePath, fmt.Sprintf("BAT%d", i)))
	if err != nil {
		return Battery{}, err
	}
	c, err := parseCharge(si["energy_now"], si["energy_full"])
	if err != nil {
		return Battery{}, fmt.Errorf("couldn't parse battery charge: %v\n", err)
	}
	state := Unknown
	err = state.parse(si["status"])
	if err != nil {
		return Battery{}, err
	}
	if state == Unknown && c.String() == "full" {
		// Full batteries sometimes are reported as "unknown", for some
		// reason.
		state = Full
	}
	return Battery{
		State:  state,
		Charge: c,
	}, nil
}

// Get reads SysFS to find state of all batteries.
func Get() ([]Battery, error) {
	path := filepath.Join(BasePath, "BAT*")
	glob, err := filepath.Glob(path)
	if err != nil {
		return []Battery{}, fmt.Errorf("failed to read battery info from SysFS: %v\n", err)
	}
	if len(glob) == 0 {
		return []Battery{}, fmt.Errorf("no battery info found in SysFS path %s\n", path)
	}
	result := make([]Battery, len(glob))
	for i := 0; i < len(glob); i++ {
		b, err := GetNumber(i)
		if err != nil {
			return []Battery{}, err
		}
		result[i] = b
	}
	return result, nil
}
