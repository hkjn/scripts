// brightness provides a library for adjusting intel_backlight light levels.
//
// Set the SUID bit (allowing any user to run the script with root
// permissions, with associated risks) as follows:
// $ go build tools/dec_brightness.go
// # mv dec_brightness /usr/bin/inc_intel_backlight
// # chown root:root /usr/bin/inc_intel_backlight
// # chmod 4755 /usr/bin/inc_intel_backlight
package brightness

import (
	"io/ioutil"
	"log"
	"strconv"
	"strings"
)

var (
	brightness_path = "/sys/class/backlight/intel_backlight/brightness"
	max_path        = "/sys/class/backlight/intel_backlight/max_brightness"
	levels          = []int{
		1, 5, 8, 12, 18, 27, 40, 60, 90, 135, 202, 303, 454, 852,
	}
)

// getMax gets the maximum light value.
func getMax() (int, error) {
	bytes, err := ioutil.ReadFile(max_path)
	if err != nil {
		return -1, err
	}
	parts := strings.Split(string(bytes), "\n")
	// Remove trailing \n.
	max, err := strconv.Atoi(parts[0])
	if err != nil {
		return -1, err
	}
	log.Printf("Max brightness = %v\n", max)
	return max, nil
}

// Set sets brightness to value.
func Set(value int) error {
	max, err := getMax()
	if err != nil {
		return err
	}

	if value > max {
		log.Println("Value > max value (%v > %v); using %v instead\n", value, max, max)
		value = max
	}
	if value < 0 {
		log.Println("Value < min value (%v < 0); using 0 instead\n", value)
		value = 0
	}

	new_string := strconv.FormatInt(int64(value), 10) + "\n"
	out_bytes := []byte(new_string)

	err = ioutil.WriteFile(brightness_path, out_bytes, 0600)
	if err != nil {
		return err
	}
	log.Printf("Wrote %v to %v.\n", value, brightness_path)
	return nil
}

// Inc increases the light level to the nearest higher bucket.
func Inc() error {
	log.Printf("Inc()\n")
	current, err := Get()
	if err != nil {
		return err
	}
	for _, v := range levels {
		if v > current {
			log.Printf("Next highest value is %d; setting it\n", v)
			return Set(v)
		}
	}
	highest := levels[len(levels)-1]
	log.Printf("No higher bucket, resetting to highest value %d\n", highest)
	return Set(highest)
}

// Dec decreases the light level to the nearest lower bucket.
func Dec() error {
	log.Printf("Dec()\n")
	current, err := Get()
	if err != nil {
		return err
	}
	for i, v := range levels {
		if v >= current {
			if i == 0 {
				log.Printf("First value is higher/equal to than current; resetting to %d\n", v, levels[0])
				return Set(levels[0])
			} else {
				log.Printf("First value lower than current is %d; setting it\n", levels[i-1])
				return Set(levels[i-1])
			}
		}
	}
	value := levels[len(levels)-2]
	log.Printf("No higher bucket, resetting to next highest value %d\n", value)
	return Set(value)

}

// Get retrieves the current light level.
func Get() (int, error) {
	log.Printf("Get()\n")
	bytes, err := ioutil.ReadFile(brightness_path)
	if err != nil {
		return -1, err
	}

	// Remove trailing \n.
	parts := strings.Split(string(bytes), "\n")
	current, err := strconv.Atoi(parts[0])
	if err != nil {
		return -1, err
	}
	log.Printf("Current brightness = %v\n", current)
	return current, nil
}

// Adjust adjusts the brightness by delta.
func Adjust(delta int) error {
	log.Printf("Set(%v)\n", delta)
	current, err := Get()
	if err != nil {
		return err
	}
	return Set(int(current + delta))
}
