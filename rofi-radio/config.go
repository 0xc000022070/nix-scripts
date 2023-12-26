package main

import (
	"errors"
	"fmt"
	"os"
	"path/filepath"

	"gopkg.in/yaml.v3"
)

type Config struct {
	StopBeforeSelection bool         `yaml:"stop-before-selection"`
	Beats               []BeatSource `yaml:"beats"`
	Window              struct {
		Location *int `yaml:"location"`
		YOffset  *int `yaml:"yoffset"`
		XOffset  *int `yaml:"xoffset"`
		Width    *int `yaml:"width"`
		Height   *int `yaml:"height"`
	}
}

func (c Config) validate() error {
	if c.Window.Location != nil {
		if l := *c.Window.Location; l < 0 || l > 8 {
			return errors.New("window location should be between 0 and 8")
		}
	}

	return nil
}

func getDefaultConfig() Config {
	return Config{
		StopBeforeSelection: true,
	}
}

func loadConfig() (Config, error) {
	config := getDefaultConfig()
	cfp := getConfigFilePath()

	if data, err := os.ReadFile(cfp); err == nil {
		if err := yaml.Unmarshal(data, &config); err != nil {
			return Config{}, err
		}
	}

	if err := config.validate(); err != nil {
		return Config{}, err
	}

	return config, nil
}

func getConfigFilePath() string {
	if s := os.Getenv("ROFI_RADIO_CFG"); s != "" {
		return s
	}

	configDirPath := os.Getenv("XDG_CONFIG_HOME")
	if configDirPath == "" {
		configDirPath = fmt.Sprintf("%s/.config", os.Getenv("HOME"))
	}

	os.MkdirAll(filepath.Join(configDirPath, PROGRAM_NAME), os.ModePerm)

	return filepath.Join(configDirPath, PROGRAM_NAME, "config.yaml")
}
