package main

import (
	"bytes"
	"context"
	"fmt"
	"io"
	"os"
	"os/exec"
	"os/signal"
	"strings"
	"syscall"

	"github.com/samber/lo"
)

const PROGRAM_NAME = "rofi-radio"

func main() {
	if err := killOtherBeatProcesses(); err != nil {
		panic(err)
	}

	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM, syscall.SIGKILL)
	defer stop()

	sources, err := LoadSources()
	if err != nil {
		panic(err)
		
	}

	selectedBeat, err := showMenu(ctx, sources, "", "", "")
	if err != nil {
		panic(err)
	}

	fmt.Fprintf(os.Stderr, "Loading '%s' (%s)\n", selectedBeat.Name, selectedBeat.URL)

	if err := playBeat(ctx, selectedBeat); err != nil {
		panic(err)
	}

	<-ctx.Done()
}

func getBeatsList(sources []BeatSource) []string {
	return lo.Map(sources, func(source BeatSource, i int) string {
		if source.Name != "" {
			return source.Name
		}

		return fmt.Sprintf("Beat %d", i+1)
	})
}

func showMenu(ctx context.Context, sources []BeatSource, configPath, stylePath, colorsPath string) (BeatSource, error) {
	cmdArgs := []string{
		"-dmenu",
		// "--conf", configPath,
		// "--style", stylePath,
		// "--color", colorsPath,
		"--width", "350",
		"--height", "380",
		"--cache-file", "/dev/null",
		"--hide-scroll", "--no-actions",
		// "--define=matching=fuzzy",
	}

	beats := getBeatsList(sources)

	echo := exec.CommandContext(ctx, "echo", strings.Join(beats, "\n"))
	rofi := exec.CommandContext(ctx, "rofi", cmdArgs...)

	var b bytes.Buffer

	pr, pw := io.Pipe()
	echo.Stdout = pw
	rofi.Stdin = pr
	rofi.Stdout = &b

	if err := echo.Start(); err != nil {
		return BeatSource{}, err
	}

	if err := rofi.Start(); err != nil {
		return BeatSource{}, err
	}

	go func() {
		defer pw.Close()

		echo.Wait()
	}()

	if err := rofi.Wait(); err != nil {
		return BeatSource{}, err
	}

	selectionOption := ""

	if data, err := io.ReadAll(&b); err == nil {
		selectionOption = string(strings.TrimSuffix(string(data), "\n"))
	}

	for i, beat := range beats {
		if beat == selectionOption {
			return sources[i], nil
		}
	}

	return BeatSource{}, fmt.Errorf("rofi returned an unexpected output")
}
