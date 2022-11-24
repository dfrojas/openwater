#![allow(unused_imports)]
// https://blog.devgenius.io/reading-and-writing-a-json-file-in-rust-2731da8d6ad0
#[macro_use]
mod args;

// use args::{OpenWaterArgs, ManualCommand, InputType};
use args::{OpenWaterArgs};
use clap::Parser;
use serde_json;
use serde_json::{Result, Value};

use serde::{Deserialize, Serialize};

use std::fs::File;
use std::io::prelude::*;

#[derive(Serialize, Deserialize)]
struct Address {
    street: String,
    city: String,
}


fn main() -> Result<()> {
    //let _args : OpenWaterArgs = OpenWaterArgs::parse();
    // test
    //println!("{:?}", 123);

    let mut file = File::open("src/my-dives.ssrf").expect("File not found JJAJA");
    let mut data = String::new();
    file.read_to_string(&mut data).expect("Error while reading file");
    println!("{}", data);

    // args.input_type {
    //     InputType::Manual(user) => "Hola",
    // };
    
    // println!("{:?}", args.);

    // let m = ManualCommand {
    //     //date: String::from("someone@example.com"),
    //     //depth: String::from("someone@example.com")
    //     Box::new(args::ManualCommand)
    // };

    // let address = Address {
    //     street: "10 Downing Street".to_owned(),
    //     city: "London".to_owned(),
    // };

    // let j = serde_json::to_string(&address)?;

    // // println!("{:?}", j);
    // println!("{}", j);


    Ok(())
}
