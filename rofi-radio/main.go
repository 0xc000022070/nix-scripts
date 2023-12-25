package main

import (
	"context"
	"fmt"
	"os"
	"strings"

	"github.com/samber/lo"
)

const PROGRAM_NAME = "rofi-radio"

func main() {
	sources, err := LoadSources()
	if err != nil {
		panic(err)
	}

	ctx, cancel := context.WithCancel(context.Background())

	switch {
	default:
	}

	fmt.Printf("killOtherBeatProcesses(): %v\n", killOtherBeatProcesses())

	// os.Getpid()

	fmt.Println(getBeatsList(sources))

	source := sources[9]

	fmt.Fprintf(os.Stderr, "Loading '%s' (%s)", source.Name, source.URL)

	fmt.Printf("playBeat(ctx, source): %v\n", playBeat(ctx, source))


	

	cancel()
}

func getBeatsList(sources []BeatSource) string {
	items := lo.Map(sources, func(source BeatSource, i int) string {
		if source.Name != "" {
			return source.Name
		}

		return fmt.Sprintf("Beat %d (%s)", i+1, source.URL)
	})

	return strings.Join(items, "\n")
}
