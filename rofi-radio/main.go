package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"os/signal"
	"syscall"
)

const PROGRAM_NAME = "rofi-radio"

func main() {
	if err := killOtherBeatProcesses(); err != nil {
		log.Fatalf("unable to kill other rofi-radio processes: %s", err.Error())
	}

	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM, syscall.SIGKILL)
	defer stop()

	config, err := loadConfig()
	if err != nil {
		log.Fatalf("config error: %s", err.Error())
	}

	selectedBeat, err := showMenu(ctx, config)
	if err != nil {
		log.Fatal(err)
	}

	fmt.Fprintf(os.Stderr, "Playing '%s' (%s)\n", selectedBeat.Name, selectedBeat.URL)

	if err := playBeat(ctx, selectedBeat); err != nil {
		panic(err)
	}

	<-ctx.Done()
}
