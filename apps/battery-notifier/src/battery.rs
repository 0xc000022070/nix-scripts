use chrono::Utc;
use linuxver::version as get_linux_version;
use serde::Deserialize;
use std::{fmt, fs};

pub const BATTERY_DANGER_PATH: &str = "./assets/battery-danger.png";

pub const CHARGING_BATTERY_SOUND: &[u8] = include_bytes!("./../assets/sounds/charging.mp3");
pub const REMINDER_BATTERY_SOUND: &[u8] = include_bytes!("./../assets/sounds/30.mp3");
pub const THREAT_BATTERY_SOUND: &[u8] = include_bytes!("./../assets/sounds/5.mp3");
pub const WARN_BATTERY_SOUND: &[u8] = include_bytes!("./../assets/sounds/15.mp3");

struct Debug {
    options: DebugOptions,
    use_first: bool,
    last_update_at: chrono::NaiveTime,
}

impl Debug {
    fn get_state(&self) -> DebugState {
        if self.use_first {
            self.options.from.clone()
        } else {
            self.options.to.clone()
        }
    }

    fn should_toggle_state(&self, now: chrono::NaiveTime) -> bool {
        let diff = now - self.last_update_at;
        diff.num_seconds() >= self.options.seconds_between
    }

    fn toggle_state(&mut self) {
        self.use_first = !self.use_first
    }
}

pub struct PowerSupplyClass {
    path: String,
    debug: Option<Debug>,
}

impl PowerSupplyClass {
    pub fn new(debug_file_path: Option<String>) -> PowerSupplyClass {
        let kernel_version = get_linux_version().expect("must use a Linux kernel");
        if kernel_version.major == 2 && kernel_version.minor < 6 {
            panic!("This program requires Linux 2.6 or higher");
        }

        let class = match os_info::get().os_type() {
            os_info::Type::Ubuntu => "BAT0",
            _ => {
                if kernel_version.major < 3
                    || (kernel_version.major == 3 && kernel_version.minor < 19)
                {
                    "BAT0"
                } else {
                    "BAT1"
                }
            }
        };

        let now = Utc::now().time();

        PowerSupplyClass {
            path: format!("/sys/class/power_supply/{}", class),
            debug: debug_file_path.map(|file_path| Debug {
                options: DebugOptions::parse(file_path),
                last_update_at: now,
                use_first: true,
            }),
        }
    }

    pub fn get_capacity(&mut self) -> u8 {
        if self.debug.is_some() {
            let debug = self.debug.as_mut().unwrap();
            let now = Utc::now().time();

            if debug.should_toggle_state(now) {
                debug.last_update_at = now;
                debug.toggle_state();
            };

            return debug.get_state().capacity;
        }

        let raw_capacity: String = fs::read_to_string(self.get_capacity_path())
            .expect("Read battery capacity file")
            .replace("\n", "");

        raw_capacity
            .parse::<u8>()
            .expect("BAT1 capacity file doesn't contains a number")
    }

    pub fn get_status(&mut self) -> String {
        if self.debug.is_some() {
            let debug = self.debug.as_mut().unwrap();
            let now = Utc::now().time();

            if debug.should_toggle_state(now) {
                debug.last_update_at = now;
                debug.toggle_state();
            };

            return debug.get_state().status;
        }

        fs::read_to_string(self.get_status_path())
            .expect("Read battery status file")
            .replace("\n", "")
    }

    fn get_capacity_path(&self) -> String {
        format!("{}/capacity", self.path)
    }

    fn get_status_path(&self) -> String {
        format!("{}/status", self.path)
    }
}

#[derive(Clone, Copy)]
pub enum Urgency {
    CRITICAL,
    NORMAL,
    LOW,
}

impl Urgency {
    pub fn get_sound(&self) -> &[u8] {
        match self {
            Urgency::CRITICAL => THREAT_BATTERY_SOUND,
            Urgency::NORMAL => WARN_BATTERY_SOUND,
            Urgency::LOW => REMINDER_BATTERY_SOUND,
        }
    }
}

impl fmt::Display for Urgency {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Urgency::CRITICAL => write!(f, "critical"),
            Urgency::NORMAL => write!(f, "normal"),
            Urgency::LOW => write!(f, "low"),
        }
    }
}

#[derive(PartialEq)]
pub enum BatteryNotificationLevel {
    NoConflict,
    Reminder,
    Warn,
    Threat,
    Charging,
}

impl fmt::Display for BatteryNotificationLevel {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            BatteryNotificationLevel::NoConflict => write!(f, "no conflict(0)"),
            BatteryNotificationLevel::Reminder => write!(f, "reminder(1)"),
            BatteryNotificationLevel::Warn => write!(f, "warn(2)"),
            BatteryNotificationLevel::Threat => write!(f, "threat(3)"),
            BatteryNotificationLevel::Charging => write!(f, "charging(-1)"),
        }
    }
}

#[derive(Clone, Deserialize)]
struct DebugState {
    status: String,
    capacity: u8,
}

#[derive(Clone, Deserialize)]
pub struct DebugOptions {
    from: DebugState,
    to: DebugState,
    seconds_between: i64,
}

impl DebugOptions {
    pub fn parse(debug_file_path: String) -> Self {
        let content = fs::read_to_string(debug_file_path).expect("read file path");
        let options: DebugOptions = serde_yaml::from_str(&content).expect("parse debug file");

        options
    }
}
