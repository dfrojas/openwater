use clap:: {
    Args,
    Parser,
    Subcommand
};


#[derive(Parser, Debug)]
#[clap(author = "Diego Fernando Rojas", version, about)]
pub struct OpenWaterArgs {
    #[clap(subcommand)]
    pub input_type: InputType,
}

#[derive(Debug, Subcommand)]
pub enum InputType {
    Manual(ManualCommand),
}

#[derive(Debug, Args)]
pub struct ManualCommand {
    /// Date of the dive.
    #[arg(long = "date")]
    pub date: String,
    /// Time of the dive.
    #[arg(long = "time")]
    pub time: Option<String>,
    /// Max depth of the dive.
    #[arg(long = "depth")]
    pub depth: String,
}

