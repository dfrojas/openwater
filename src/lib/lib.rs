use quick_xml::de::from_str;
use serde::Deserialize;
use std::fs;
use thiserror::Error;

#[derive(Debug, Error)]
pub enum UDDFError {
    #[error("Error al leer el archivo: {0}")]
    FileError(#[from] std::io::Error),
    #[error("Error al parsear XML: {0}")]
    ParseError(#[from] quick_xml::DeError),
}

#[derive(Debug, Deserialize)]
pub struct UDDF {
    #[serde(rename = "generator")]
    generator: Generator,
    #[serde(rename = "diver")]
    diver: Diver,
}

#[derive(Debug, Deserialize)]
struct Generator {
    name: String,
    version: String,
    date: String,
}

#[derive(Debug, Deserialize)]
struct Diver {
    owner: Owner,
}

#[derive(Debug, Deserialize)]
struct Owner {
    personal: Personal,
    contact: Contact,
    equipment: Equipment,
}

#[derive(Debug, Deserialize)]
struct Personal {
    firstname: String,
    lastname: String,
    birthday: String,
}

#[derive(Debug, Deserialize)]
struct Contact {
    email: String,
}

#[derive(Debug, Deserialize)]
struct Equipment {
    divecomputer: DiveComputer,
}

#[derive(Debug, Deserialize)]
struct DiveComputer {
    name: String,
    serialnumber: String,
}

impl UDDF {
    pub fn from_file(path: &str) -> Result<Self, UDDFError> {
        let content = fs::read_to_string(path)?;
        let uddf: UDDF = from_str(&content)?;
        Ok(uddf)
    }
}

pub fn parse_uddf_file(path: &str) -> Result<UDDF, UDDFError> {
    let uddf = UDDF::from_file(path)?;
    Ok(uddf)
}
