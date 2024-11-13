use std::error::Error;

use clap::Parser;

#[macro_use]
mod args;
mod actions;

use args::{OpenWaterCli, OutputKind};

fn main() -> Result<(), Box<dyn Error>> {
    let args: OpenWaterCli = OpenWaterCli::parse();

    let input: String = args.input.as_path().display().to_string();

    match args.output {
        OutputKind::Json => {
            let json = actions::to_json(&input)?;
            println!("{:?}", json);
        } // OutputKind::Plot => actions::to_plot(&input)?,
    };

    Ok(())
}
