use chrono::Utc;
use clap::Parser;
use soloud::{audio::Wav, AudioExt, LoadExt, Soloud};
use std::{
    io::{self, Error},
    process::{Command, Output},
    thread,
    time::{self},
};

mod battery;
use battery::*;

mod helpers;
use helpers::is_program_in_path;

#[derive(Parser, Debug)]
#[command(author, version, about, long_about = None)]
struct Args {
    #[arg(short, long)]
    debug_file: Option<String>,
}

const APP_NOTIFICATION_ID: &str = "string:x-dunst-stack-tag:battery";

fn main() {
    let args = Args::parse();

    let start_time = Utc::now().time();

    let sleep_time = time::Duration::from_millis(700); // 0.7s
    let mut last_notification_level = BatteryNotificationLevel::NoConflict;
    let mut psc = PowerSupplyClass::new(args.debug_file);

    loop {
        let capacity = psc.get_capacity();
        let status = psc.get_status();

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

fn send_desktop_notification(urgency: Urgency, title: &str, content: &str) -> io::Result<Output> {
    if is_program_in_path("notify-send") {
        return Command::new("notify-send")
            .arg(format!("--urgency={}", urgency.to_string()))
            .arg(format!("--hint={}", APP_NOTIFICATION_ID))
            .arg(format!("--icon={}", BATTERY_DANGER_PATH))
            .arg(title)
            .arg(content)
            .output();
    } else {
        let err = Error::new(io::ErrorKind::NotFound, "notify-send were found in $PATH");
        return Result::Err(err);
    }
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

// Calculates the notification level based on the provided battery capacity.
fn get_notification_level(capacity: u8) -> BatteryNotificationLevel {
    match capacity {
        16..=30 => BatteryNotificationLevel::Reminder,
        6..=15 => BatteryNotificationLevel::Warn,
        1..=5 => BatteryNotificationLevel::Threat,
        _ => BatteryNotificationLevel::NoConflict,
    }
}
