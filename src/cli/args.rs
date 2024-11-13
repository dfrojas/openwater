use clap::Parser;

#[derive(clap::ValueEnum, Clone, Debug, Eq, PartialEq)]
pub enum OutputKind {
    Json,
    Plot,
}

#[derive(Parser, Debug)]
#[clap(author = "Diego Fernando Rojas", version, about)]
pub struct OpenWaterCli {
    #[clap(short, long)]
    pub input: std::path::PathBuf,

    #[clap(short, long, value_enum)]
    pub output: OutputKind,
}
