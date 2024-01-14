use std::{env, fs};

pub fn is_program_in_path(program_name: &str) -> bool {
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
