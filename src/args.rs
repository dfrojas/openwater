use clap::Parser;
use std::fmt;

#[derive(clap::ValueEnum, Clone, Debug, Eq, PartialEq)]
pub enum VendorKind {
    CressiLeonardo,
    MaresGenius
}

impl fmt::Display for VendorKind {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        match self {
            VendorKind::CressiLeonardo => write!(f, "cressi-leonardo"),
            VendorKind::MaresGenius => write!(f, "mares-genius"),
        }
    }
}

#[derive(clap::ValueEnum, Clone, Debug)]
enum OutputKind {
    Json,
    Plot
}

#[derive(Parser, Debug, Clone)]
#[clap(author = "Diego Fernando Rojas", version, about)]
pub struct OpenWaterCli {
    #[clap(value_enum)]
    pub vendor: VendorKind,
    //path: std::path::PathBuf,
    #[clap(value_enum)]
    output: OutputKind
}
