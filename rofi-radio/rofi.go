package main

import (
	"bytes"
	"context"
	"errors"
	"io"
	"os"
	"os/exec"
	"strings"
)

var (
	errRofiStopped       = errors.New("child rofi process was killed so there's nothing else to do")
	errRofiUnknownOutput = errors.New("child rofi process returned an unexpected output")
)

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

	beats := getBeatNames(sources)

	echo := exec.CommandContext(ctx, "echo", strings.Join(beats, "\n"))
	rofi := exec.CommandContext(ctx, "rofi", cmdArgs...)

	var b bytes.Buffer

	pr, pw := io.Pipe()
	echo.Stdout = pw
	rofi.Stdin = pr
	rofi.Stdout = &b
	rofi.Stderr = os.Stderr

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
		if strings.Contains(err.Error(), "signal:") {
			return BeatSource{}, errRofiStopped
		}

		return BeatSource{}, err
	}

	selectionOption := ""

	if data, err := io.ReadAll(&b); err == nil {
		selectionOption = strings.TrimSuffix(string(data), "\n")
	}

	for i, beat := range beats {
		if beat == selectionOption {
			return sources[i], nil
		}
	}

	return BeatSource{}, errRofiUnknownOutput
}
