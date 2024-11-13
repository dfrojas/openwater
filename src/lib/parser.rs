use super::{UDDFError, UDDF};
use quick_xml::de::from_str;
use std::fs;

impl UDDF {
    pub fn from_file(path: &str) -> Result<Self, UDDFError> {
        let content = fs::read_to_string(path)?;
        let uddf: UDDF = from_str(&content)?;
        Ok(uddf)
    }
}

pub fn uddf_parse_file(path: &str) -> Result<UDDF, UDDFError> {
    let uddf = UDDF::from_file(path)?;
    Ok(uddf)
}
