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
	errRofiStopped       = errors.New("child rofi process was stopped so there's nothing else to do")
	errRofiUnknownOutput = errors.New("child rofi process returned an unexpected output")
)

func showMenu(ctx context.Context, config Config) (Broadcaster, error) {
	broadcasters := getBroadcasterNames(config.Broadcasters)

	echo := exec.CommandContext(ctx, "echo", strings.Join(broadcasters, "\n"))
	rofi := exec.CommandContext(ctx, "rofi", getRofiCmdArgs(config)...)

	var b bytes.Buffer

	pr, pw := io.Pipe()
	echo.Stdout = pw
	rofi.Stdin = pr
	rofi.Stdout = &b
	rofi.Stderr = os.Stderr

	if err := echo.Start(); err != nil {
		return Broadcaster{}, err
	}

	if err := rofi.Start(); err != nil {
		return Broadcaster{}, err
	}

	go func() {
		defer pw.Close()

		echo.Wait()
	}()

	if err := rofi.Wait(); err != nil {
		if strings.Contains(err.Error(), "signal:") {
			return Broadcaster{}, errRofiStopped
		} else if strings.Contains(err.Error(), "exit status") {
			return Broadcaster{}, errRofiStopped
		}

		return Broadcaster{}, err
	}

	selectionOption := ""

	if data, err := io.ReadAll(&b); err == nil {
		selectionOption = strings.TrimSuffix(string(data), "\n")
	}

	for i, beat := range broadcasters {
		if beat == selectionOption {
			return config.Broadcasters[i], nil
		}
	}

	return Broadcaster{}, errRofiUnknownOutput
}

func getRofiCmdArgs(config Config) []string {
	args := []string{
		"-dmenu",
		"-config", os.Getenv("ROFI_RADIO_ROFI_CFG"),
		"-cache-file", "/dev/null",
		"-hide-scroll", "--no-actions",
		"-modi", PROGRAM_NAME,
	}

	if config.Window.Location != nil {
		args = append(args, "-location", strconv.Itoa(*config.Window.Location))
	}

	return args
}
