use linuxver::version as get_linux_version;
use std::{fmt, fs};

pub const BATTERY_DANGER_PATH: &str = "./assets/battery-danger.png";

pub const CHARGING_BATTERY_SOUND: &[u8] = include_bytes!("./../assets/sounds/charging.mp3");
pub const REMINDER_BATTERY_SOUND: &[u8] = include_bytes!("./../assets/sounds/30.mp3");
pub const THREAT_BATTERY_SOUND: &[u8] = include_bytes!("./../assets/sounds/5.mp3");
pub const WARN_BATTERY_SOUND: &[u8] = include_bytes!("./../assets/sounds/15.mp3");

pub struct PowerSupplyClass {
    path: String,
}

impl PowerSupplyClass {
    pub fn new() -> PowerSupplyClass {
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

        PowerSupplyClass {
            path: format!("/sys/class/power_supply/{}", class),
        }
    }

    pub fn get_capacity(&self) -> u8 {
        let raw_capacity: String = fs::read_to_string(self.get_capacity_path())
            .expect("Read battery capacity file")
            .replace("\n", "");

        raw_capacity
            .parse::<u8>()
            .expect("BAT1 capacity file doesn't contains a number")
    }

    pub fn get_status(&self) -> String {
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
