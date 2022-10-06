mod lib;

use clap::Parser;
pub use crate::lib::read_file;

#[derive(Parser)]
struct Cli {
    vendor: String, // This has to be an Enum later.
    logs_path: std::path::PathBuf,
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let args = Cli::parse();
    openwater::read_file(&args.logs_path, &mut std::io::stdout())?;
    Ok(())
}
