mod lib;
use clap::Parser;
pub use crate::lib::{read_file, handle_user_input};

#[derive(Parser)]
#[clap(author = "Diego Fernando Rojas", version, about)]
struct Cli {
    // TODO: Implement short and long
    vendor: Option<String>, // This has to be an Enum later.
    logs_path: Option<std::path::PathBuf>,
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let get_args: Vec<_> = std::env::args().collect();
    // If there is only one element, means that there was no arguments passed.
    // The unique element is the name of the program.
    if get_args.len() == 1 {
        openwater::handle_user_input();
        Ok(());
    }
    let args = Cli::parse();
    openwater::read_file(&args.logs_path, &mut std::io::stdout())?;
    Ok(());
}
