#[macro_use]
mod args;
mod vendors;

use args::{OpenWaterCli, VendorKind};
use vendors:: {BaseVendor, MaresGenius, CressiLeonardo};

use clap::Parser;
use serde_json;
use serde_json::Result;
use std::collections::HashMap;

fn main() -> Result<()> {
    let args : OpenWaterCli = OpenWaterCli::parse();

    let mut vendors_map: HashMap<String, Box<dyn BaseVendor>> = HashMap::new();

    vendors_map.insert(VendorKind::MaresGenius.to_string(), Box::new(MaresGenius));
    vendors_map.insert(VendorKind::CressiLeonardo.to_string(), Box::new(CressiLeonardo));

    let vendor: String = args.vendor.to_string();
    vendors_map.get(&vendor);

    Ok(())
}
