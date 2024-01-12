use chrono::Utc;
use core::fmt;
use soloud::{audio::Wav, AudioExt, LoadExt, Soloud};
use std::{
    env, fs,
    io::{self, Error},
    process::{Command, Output},
    thread,
    time::{self, Duration},
};

const BATTERY_CAPACITY_PATH: &str = "/sys/class/power_supply/BAT1/capacity";
const BATTERY_STATUS_PATH: &str = "/sys/class/power_supply/BAT1/status";

const BATTERY_DANGER_PATH: &str = "./assets/battery-danger.png";

const NOTIFY_SEND: &str = "notify-send";
const DUNSTIFY: &str = "dunstify";

const CHARGING_BATTERY_SOUND: &[u8] = include_bytes!("./../assets/sounds/charging.mp3");
const REMINDER_BATTERY_SOUND: &[u8] = include_bytes!("./../assets/sounds/30.mp3");
const THREAT_BATTERY_SOUND: &[u8] = include_bytes!("./../assets/sounds/5.mp3");
const WARN_BATTERY_SOUND: &[u8] = include_bytes!("./../assets/sounds/15.mp3");

const APP_NOTIFICATION_ID: &str = "string:x-dunst-stack-tag:battery";

#[derive(Clone, Copy)]
enum Urgency {
    CRITICAL,
    NORMAL,
    LOW,
}

#[derive(PartialEq)]
enum BatteryNotificationLevel {
    NoConflict,
    Reminder,
    Warn,
    Threat,
    Charging,
}

impl Urgency {
    fn get_sound(&self) -> &[u8] {
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

fn main() {
    let start_time = Utc::now().time();

    let sleep_time = time::Duration::from_millis(700); // 0.7s
    let mut last_notification_level = BatteryNotificationLevel::NoConflict;

    loop {
        let raw_capacity: String = fs::read_to_string(BATTERY_CAPACITY_PATH)
            .expect("Read battery capacity file")
            .replace("\n", "");

        let capacity: u8 = raw_capacity
            .parse::<u8>()
            .expect("BAT1 capacity file doesn't contains a number");

        let status: String = fs::read_to_string(BATTERY_STATUS_PATH)
            .expect("Read battery status file")
            .replace("\n", "");

        println!("[DEBUG] Current capacity: {} Status: {}", capacity, status);

        if status == "Charging" && last_notification_level != BatteryNotificationLevel::Charging {
            println!("[DEBUG] Now the battery is charging...");
            println!(
                "[DEBUG] The last notified capacity will be restarted to 0 (it was {})",
                last_notification_level
            );

            let current_time = Utc::now().time();

            if (current_time - start_time).num_seconds() > 5 {
                send_sound_notification(CHARGING_BATTERY_SOUND);
            } else {
                println!("[WARNING] the app started with the computer plugged in, nothing to do");
            }

            last_notification_level = BatteryNotificationLevel::Charging
        } else if status == "Discharging" || status == "Not charging" {
            let default_content = format!("Charge: {}%", capacity);

            let mut notify_capacity = |urgency: Urgency, title: &str, content: &str| {
                let current_notification_level = get_notification_level(capacity);

                println!(
                    "[DEBUG] Last notification level: {}, Current notification level: {}",
                    last_notification_level, current_notification_level
                );

                if last_notification_level != current_notification_level {
                    last_notification_level = current_notification_level;

                    match send_desktop_notification(urgency, title, content) {
                        Ok(r) => println!("[DEBUG] Battery notification: {:#?}", r),
                        Err(error) => {
                            println!("[ERROR] Battery notification: {}", error.to_string())
                        }
                    };

                    send_sound_notification(urgency.get_sound())
                }
            };

            match get_notification_level(capacity) {
                BatteryNotificationLevel::Reminder => {
                    notify_capacity(Urgency::LOW, "Battery somewhat low", &default_content)
                }
                BatteryNotificationLevel::Warn => notify_capacity(
                    Urgency::NORMAL,
                    "Battery low",
                    format!("{}.\nPlease connect your laptop", default_content).as_str(),
                ),
                BatteryNotificationLevel::Threat => notify_capacity(
                    Urgency::CRITICAL,
                    "Battery very low",
                    format!(
                        "{}.\n\nYour computer will shut down soon! You'll regret this!",
                        default_content
                    )
                    .as_str(),
                ),
                _ => (),
            }
        }

        thread::sleep(sleep_time);
    }
}

// Calculates the notification level based on the provided battery capacity.
fn get_notification_level(capacity: u8) -> BatteryNotificationLevel {
    match capacity {
        16..=30 => BatteryNotificationLevel::Reminder,
        6..=15 => BatteryNotificationLevel::Warn,
        1..=5 => BatteryNotificationLevel::Threat,
        _ => BatteryNotificationLevel::NoConflict,
    }
}

fn send_desktop_notification(urgency: Urgency, title: &str, content: &str) -> io::Result<Output> {
    let result: io::Result<Output>;

    if is_program_in_path(DUNSTIFY) {
        result = Command::new(DUNSTIFY)
            .arg("--appname=battery-notifier")
            .arg(format!("--urgency={}", urgency.to_string()))
            .arg(format!("--hints={}", APP_NOTIFICATION_ID))
            .arg(format!("--icon={}", BATTERY_DANGER_PATH))
            .arg(title)
            .arg(content)
            .output();
    } else if is_program_in_path(NOTIFY_SEND) {
        result = Command::new(NOTIFY_SEND)
            .arg(format!("--urgency={}", urgency.to_string()))
            .arg(format!("--hint={}", APP_NOTIFICATION_ID))
            .arg(format!("--icon={}", BATTERY_DANGER_PATH))
            .arg(title)
            .arg(content)
            .output();
    } else {
        let err = Error::new(
            io::ErrorKind::NotFound,
            "neither notify-send or dunstify were found in $PATH",
        );
        return Result::Err(err);
    }

    result
}

fn send_sound_notification(sound: &[u8]) {
    let rsl = Soloud::default();

    match rsl {
        Ok(sl) => {
            let mut wav = Wav::default();

            match wav.load_mem(sound) {
                Ok(r) => println!("[DEBUG] Sound file has been loaded: {:#?}", r),
                Err(error) => {
                    println!("[WARN] Couldn't load sound file: {}", error.to_string())
                }
            };

            sl.play(&wav);
            while sl.voice_count() > 0 {
                thread::sleep(time::Duration::from_millis(500));
            }
        }
        Err(error) => println!(
            "[ERROR] soloud instance couldn't be correctly initialized: {}",
            error.to_string()
        ),
    }
}

fn is_program_in_path(program_name: &str) -> bool {
    if let Ok(path) = env::var("PATH") {
        for p in path.split(":") {
            let p_str = format!("{}/{}", p, program_name);

            if fs::metadata(p_str).is_ok() {
                return true;
            }
        }
    }

    false
}
