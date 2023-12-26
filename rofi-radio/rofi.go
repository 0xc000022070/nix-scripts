package main

import (
	"bytes"
	"context"
	"errors"
	"io"
	"os"
	"os/exec"
	"strconv"
	"strings"
)

var (
	errRofiStopped       = errors.New("child rofi process was killed so there's nothing else to do")
	errRofiUnknownOutput = errors.New("child rofi process returned an unexpected output")
)

func showMenu(ctx context.Context, config Config) (BeatSource, error) {
	beats := getBeatNames(config.Beats)

	echo := exec.CommandContext(ctx, "echo", strings.Join(beats, "\n"))
	rofi := exec.CommandContext(ctx, "rofi", getRofiCmdArgs(config)...)

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
			return config.Beats[i], nil
		}
	}

	return BeatSource{}, errRofiUnknownOutput
}

func getRofiCmdArgs(config Config) []string {
	args := []string{
		"-dmenu",
		// "--conf", configPath,
		// "--style", stylePath,
		// "--color", colorsPath,
		"-cache-file", "/dev/null",
		"-hide-scroll", "--no-actions",
		"-modi", PROGRAM_NAME,
		// "--define=matching=fuzzy",
	}

	if config.Window.Height != nil {
		args = append(args, "-height", strconv.Itoa(*config.Window.Height))
	} else {
		args = append(args, "-height", "350")
	}

	if config.Window.Width != nil {
		args = append(args, "-width", strconv.Itoa(*config.Window.Width))
	} else {
		args = append(args, "-width", "380")
	}

	if config.Window.XOffset != nil {
		args = append(args, "-xoffset", strconv.Itoa(*config.Window.XOffset))
	}

	if config.Window.YOffset != nil {
		args = append(args, "-yoffset", strconv.Itoa(*config.Window.YOffset))
	}

	if config.Window.Location != nil {
		args = append(args, "-location", strconv.Itoa(*config.Window.Location))
	}

	return args
}
