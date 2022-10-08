mod lib;
pub use crate::lib::{handle_with_file, handle_with_manual_inputs};
use clap::Parser;

#[derive(Parser)]
#[clap(author = "Diego Fernando Rojas", version, about)]
struct Cli {
    // TODO: Implement short and long
    vendor: Option<String>, // This has to be an Enum later.
    logs_path: Option<std::path::PathBuf>,
    //action: String, // The action to be executed. Has to be an Enum later.
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let get_args: Vec<_> = std::env::args().collect();
    // If there is only one element, means that there was no arguments passed.
    // The unique element is the name of the program.
    if get_args.len() == 1 {
        openwater::handle_with_manual_inputs();
    }
    let args = Cli::parse();
    openwater::handle_with_file(args.logs_path.as_ref(), &mut std::io::stdout())?;
    Ok(())
}
