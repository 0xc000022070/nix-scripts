package main

import (
	"fmt"
	"os"
	"strings"

	"github.com/goccy/go-json"
	"github.com/samber/lo"
)

type BeatSource struct {
	Name    string `yaml:"name"`
	URL     string `yaml:"url"`
	Shuffle bool   `yaml:"shuffle"`
}

func (bs BeatSource) CmdArgs() []string {
	args := make([]string, 0, 3)

	if bs.Shuffle {
		args = append(args, "--shuffle")
	}

	args = append(args, "--vid=no", bs.URL)

	return args
}

func LoadSources(sourcesFilePath string) ([]BeatSource, error) {
	fp := sourcesFilePath

	info, err := os.Stat(fp)
	if err != nil {
		if os.IsNotExist(err) {
			return nil, fmt.Errorf("file '%s' does not exist", fp)
		}

		return nil, fmt.Errorf("unable to stat file '%s': %w", fp, err)
	} else if info.IsDir() {
		return nil, fmt.Errorf("%s is a directory", fp)
	}

	content, err := os.ReadFile(fp)
	if err != nil {
		return nil, fmt.Errorf("unable to read file '%s': %w", fp, err)
	}

	var sources []BeatSource

	if err := json.Unmarshal(content, &sources); err != nil {
		return nil, fmt.Errorf("unable to deserialize '%s' as JSON file: %w", fp, err)
	}

	for i, source := range sources {
		sources[i].Name = strings.TrimSpace(source.Name)
		sources[i].URL = strings.TrimSpace(source.URL)
	}

	return sources, nil
}

func getBeatNames(sources []BeatSource) []string {
	return lo.Map(sources, func(source BeatSource, i int) string {
		if source.Name != "" {
			return source.Name
		}

		return fmt.Sprintf("Beat %d", i+1)
	})
}
