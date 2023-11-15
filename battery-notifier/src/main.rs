use core::fmt;
use std::{
    env, fs,
    io::{self, Error},
    process::{Command, Output},
    thread, time,
};

const BATTERY_CAPACITY_PATH: &str = "/sys/class/power_supply/BAT1/capacity";
const BATTERY_STATUS_PATH: &str = "/sys/class/power_supply/BAT1/status";

const BATTERY_DANGER_PATH: &str = "./assets/battery-danger.png";

const NOTIFY_SEND: &str = "notify-send";
const DUNSTIFY: &str = "dunstify";

enum Urgency {
    CRITICAL,
    NORMAL,
    LOW,
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

fn main() {
    let sleep_time = time::Duration::from_millis(700); // 0.7s
    let mut last_notified_capacity: u8 = 0;

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

        if status == "Discharging" || status == "Not charging" {
            let default_content = format!("Charge: {}%", capacity);

            let mut notify_capacity = |urgency: Urgency, title: &str, content: &str, icon: &str| {
                println!("[DEBUG] Last notified capacity: {}", last_notified_capacity);

                if last_notified_capacity != capacity {
                    last_notified_capacity = capacity;

                    match notify(urgency, title, content, icon) {
                        Ok(r) => println!("[DEBUG] Battery notification: {:#?}", r),
                        Err(error) => {
                            println!("[ERROR] Battery notification: {}", error.to_string())
                        }
                    };
                }
            };

            match capacity {
                30 => notify_capacity(
                    Urgency::LOW,
                    "Battery somewhat low",
                    &default_content,
                    BATTERY_DANGER_PATH,
                ),
                15 => notify_capacity(
                    Urgency::NORMAL,
                    "Battery low",
                    format!("{}.\nPlease connect your laptop", default_content).as_str(),
                    BATTERY_DANGER_PATH,
                ),
                5 => notify_capacity(
                    Urgency::CRITICAL,
                    "Battery very low",
                    format!("{}.\nYour computer will shut down soon", default_content).as_str(),
                    BATTERY_DANGER_PATH,
                ),
                _ => (),
            }
        }

        thread::sleep(sleep_time);
    }
}

fn notify(urgency_level: Urgency, title: &str, content: &str, icon: &str) -> io::Result<Output> {
    if is_program_in_path(DUNSTIFY) {
        return Command::new(DUNSTIFY)
            .arg(format!("--urgency={}", urgency_level.to_string()))
            .arg("--appname=battery-notifier")
            .arg("--hints=string:x-dunst-stack-tag:battery")
            .arg(format!("--icon={}", icon))
            .arg(title)
            .arg(content)
            .output();
    } else if is_program_in_path(NOTIFY_SEND) {
        return Command::new(NOTIFY_SEND)
            .arg(format!("--urgency={}", urgency_level.to_string()))
            .arg(format!("--icon={}", icon))
            .arg(title)
            .arg(content)
            .output();
    }

    let err = Error::new(
        io::ErrorKind::NotFound,
        "neither notify-send or dunstify were found in $PATH",
    );
    return Result::Err(err);
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
