package main

import (
	"context"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"strings"
	"syscall"

	"github.com/shirou/gopsutil/v3/process"
)

func playBeat(ctx context.Context, source Broadcaster) error {
	p, err := exec.LookPath("mpv")
	if err != nil {
		return errors.New("could not find mpv executable")
	}

	cmd := exec.CommandContext(ctx, p, source.CmdArgs()...)

	err = cmd.Run()
	if err != nil && !strings.Contains(err.Error(), "signal:") {
		return fmt.Errorf("error running mpv command: %w", err)
	}

	return nil
}

func killOtherBeatProcesses() error {
	processes, err := process.Processes()
	if err != nil {
		return err
	}

	currentPid := int32(os.Getpid())

	for _, p := range processes {
		n, err := p.Name()
		if err != nil {
			return fmt.Errorf("unable name of process %d: %w", p.Pid, err)
		}

		if n == PROGRAM_NAME && p.Pid != currentPid {
			if err := p.SendSignal(syscall.SIGINT); err != nil {
				return err
			}
		}
	}

	return nil
}

// func recursiveKill(process *process.Process) error {
// 	children, err := process.Children()
// 	if err == nil {
// 		for _, p := range children {
// 			if err := recursiveKill(p); err != nil {
// 				return err
// 			}
// 		}
// 	}

// 	return process.SendSignal(syscall.SIGINT)
// }
