// use std::fs::File;
// //use std::io;
// use std::io::prelude::*;
// use std::io::BufReader;
// use std::path::PathBuf;
// use colored::Colorize;

// type ReturnedValue = Result<(), Box<dyn std::error::Error>>;

// pub fn handle_with_file(
//     logs_path: Option<&PathBuf>,
//     mut writer: impl std::io::Write,
// ) -> ReturnedValue {
//     match logs_path {
//         Some(logs_path) => {
//             let file = File::open(logs_path)?;
//             // Rust by default handles 3KB of capacity. We set 10KB.
//             // TODO: Handles this dinamically.
//             let mut content = BufReader::with_capacity(10, file);
//             let mut lines = String::new();
//             content.read_to_string(&mut lines)?;
//             writeln!(writer, "{}", lines)?;
//         }
//         None => {
//             println!("Nothing");
//         }
//     }
//     Ok(())
// }

// pub fn handle_with_manual_inputs() {
//     println!("{}", format!("Enter the date of your dive:").bold().on_blue());
//     let date = rprompt::read_reply().unwrap();
//     println!("{}", format!("At what time was your dive:").bold().on_blue());
//     let time = rprompt::read_reply().unwrap();
//     println!("{}", format!("Max depth of your dive:").bold().on_blue());
//     let depth = rprompt::read_reply().unwrap();
//     println!("{}", format!("Duration of your dive:").bold().on_blue());
//     let duration = rprompt::read_reply().unwrap();
//     println!("{}", format!("Where was your dive? (long, lat):").bold().on_blue());
//     let location = rprompt::read_reply().unwrap();
//     println!("{}", format!("Name of the divemaster:").bold().on_blue());
//     let divemaster = rprompt::read_reply().unwrap();
//     // let dive_mode = rprompt::read_reply().unwrap();
//     // let suite_type = rprompt::read_reply().unwrap();
//     // let weight = rprompt::read_reply().unwrap();
//     // let gas_type = rprompt::read_reply().unwrap();
//     // let gas_consumed = rprompt::read_reply().unwrap();
//     // let water_type = rprompt::read_reply().unwrap();
//     // let water_temp = rprompt::read_reply().unwrap();
//     // let current = rprompt::read_reply().unwrap();
// }
