use clap::Parser;
use std::io::prelude::*;
use std::io::BufReader;
use std::fs::File;


#[derive(Parser)]
struct Cli {
    vendor: String, // This has to be an Enum later.
    logs_path: std::path::PathBuf,
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let args = Cli::parse();

    let file = File::open(args.logs_path)?;
    // Rust by default handles 3KB of capacity. We set 10KB.
    // TODO: Handles this dinamically.
    let mut content = BufReader::with_capacity(10, file);
    let mut lines = String::new();
    content.read_to_string(&mut lines)?
    println!("{}", lines);

    Ok(())
}
