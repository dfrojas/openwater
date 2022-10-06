use std::path::PathBuf;
use std::fs::File;
use std::io::BufReader;
use std::io::prelude::*;


pub fn read_file(logs_path: &PathBuf, mut writer: impl std::io::Write) -> Result<(), Box<dyn std::error::Error>> {
    let file = File::open(logs_path)?;
    // Rust by default handles 3KB of capacity. We set 10KB.
    // TODO: Handles this dinamically.
    let mut content = BufReader::with_capacity(10, file);
    let mut lines = String::new();
    content.read_to_string(&mut lines)?;
    writeln!(writer, "{}", lines)?;
    Ok(())
}
