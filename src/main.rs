use std::collections::HashMap;

use clap::Parser;
use serde_json;
use serde_json::Result;

#[macro_use]
mod args;
mod vendors;

use args::{OpenWaterCli, VendorKind};
use vendors:: {BaseVendor, MaresGenius, CressiLeonardo};


fn main() -> Result<()> {
    let args : OpenWaterCli = OpenWaterCli::parse();

    let path: String = args.path.as_path().display().to_string();
    let vendor: String = args.vendor.to_string();

    let mut vendors_map: HashMap<String, Box<dyn BaseVendor>> = HashMap::new();

    vendors_map.insert(VendorKind::MaresGenius.to_string(), Box::new(MaresGenius));
    vendors_map.insert(VendorKind::CressiLeonardo.to_string(), Box::new(CressiLeonardo{path: path}));

    vendors_map.get(&vendor)
    .expect("This vendor still is not supported. Try with another brand or model")
    .run();

    Ok(())
}
