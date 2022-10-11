#[macro_use]
//mod lib;
//pub use crate::lib::{handle_with_file, handle_with_manual_inputs};
mod args;

use args::{OpenWaterArgs, ManualCommand};
use clap::Parser;
//use serde::{Serialize, Deserialize};
use serde_json::{Result, Value};



fn main() { //-> Result<(), Box<dyn std::error::Error>> {
    let args : OpenWaterArgs = OpenWaterArgs::parse();
    let p: ManualCommand = serde_json::from_str(args);
    println!("{:?}", p);
}
