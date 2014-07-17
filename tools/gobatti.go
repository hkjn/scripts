// Simple tool to show battery status from SysFS as GTK icon.
package main

import (
	"fmt"
	"log"
	"os"
	"strings"
	"time"

	"github.com/mattn/go-gtk/gtk"
	"power"
)

var levels = []string{
	"empty",
	"caution",
	"low",
	"good",
	"full",
}

var states = []string{
	"charged",
	"charging",
}

type Icon struct {
	Battery    power.Battery
	StatusIcon *gtk.StatusIcon
}

func getIcons() []Icon {
	bat, err := power.Get()
	if err != nil {
		log.Fatalf("failed to get battery info: %v\n", err)
	}
	result := make([]Icon, len(bat))
	for i, b := range bat {
		icon := Icon{
			Battery: b,
		}
		in := icon.getName()
		icon.StatusIcon = gtk.NewStatusIconFromIconName(in)
		log.Printf("Created status icon %v with icon name %s\n", icon, in)
		result[i] = icon
	}
	return result
}

// getName builds the GTK icon name.
func (i Icon) getName() string {
	state := strings.ToLower(i.Battery.State.String())
	var level string
	if i.Battery.Current < 0.1 { // TODO: Map, or something.
		level = "empty"
	} else if i.Battery.Current < 0.4 {
		level = "caution"
	} else if i.Battery.Current < 0.9 {
		level = "good"
	} else {
		level = "full"
	}
	if state == "discharging" || state == "full" {
		return fmt.Sprintf("battery-%s", level)
	} else {
		return fmt.Sprintf("battery-%s-%s", level, state)
	}
}

// update updates the icon with new battery info.
func (i *Icon) update(battery power.Battery) {
	// TODO: also set / update tooltip.
	oldName := i.getName()
	i.Battery = battery
	newName := i.getName()
	if newName != oldName {
		log.Printf("Changing icon to %q from %q..\n", newName, oldName)
		i.StatusIcon.SetFromIconName(newName)
	}
}

// poll reads battery info and sleeps for specified duration.
func poll(d time.Duration, icon []Icon) {
	for {
		bat, err := power.Get()
		if err != nil {
			log.Fatalf("failed to get battery info: %v\n", err)
		}
		for i, b := range bat {
			log.Printf("[Battery %d]: %+v\n", i, b)
			icon[i].update(b)
		}
		time.Sleep(d)
	}
}

func main() {
	gtk.Init(&os.Args)
	icons := getIcons()
	d, err := time.ParseDuration("20s")
	if err != nil {
		log.Fatalf("bad duration: %v\n", err)
	}
	go poll(d, icons)
	log.Printf("Calling gtk.Main()..")
	gtk.Main()
}
