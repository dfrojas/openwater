use std::error::Error;
use csv::ReaderBuilder;
use rprompt::read_reply;
use serde::{Deserialize, Serialize};


#[derive(Debug, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
struct CsvBuilder {
    dive_number: Option<String>,
    // date:  Option<String>,
    // time:  Option<String>,
    duration:  Option<String>,
    // max_depth: Option<f32>,
    // avg_depth: Option<f32>,
    // mode:  Option<String>,
    // air_temp: Option<f32>,
    // water_temp: Option<f32>,
    // location:  Option<String>,
    // gps:  Option<String>,
    // divemaster:  Option<String>,
    buddy: Option<String>,
    // suit:  Option<String>,
    // rating:  Option<String>,
    // visibility:  Option<String>,
    // notes:  Option<String>,
    // weight:  Option<f32>
}

#[derive(Debug, Serialize, Deserialize)]
#[serde(transparent)]
struct CsvToJson {
    dives: Vec<CsvBuilder>
}

pub fn to_json(path: &str) -> Result<(), Box<dyn Error>> {

    let mut rdr = ReaderBuilder::new().quoting(false).delimiter(b'"').from_path(path)?;
    let mut vec = Vec::new();

    for result in rdr.deserialize() {
        let record: CsvBuilder = result?;
        vec.push(record);    
    }

    let dives = CsvToJson {
        dives: vec
    };

    let json = serde_json::to_string(&dives)?;

    println!("{}", json);

    Ok(())
}

pub fn to_plot(path: &str) -> Result<(), Box<dyn Error>> {
    print!("Plotting"); 
    Ok(())
}
