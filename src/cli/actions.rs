use csv::ReaderBuilder;
use plotly::common::Title;
use plotly::layout::{Axis, Layout};
use plotly::{Bar, Plot};
use serde::{Deserialize, Serialize};
use std::error::Error;

#[derive(Debug, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
struct CsvBuilder {
    dive_number: Option<String>,
    // date:  Option<String>,
    // time:  Option<String>,
    duration: Option<String>,
    // max_depth: Option<f32>,
    avg_depth: Option<f32>,
    // mode:  Option<String>,
    // air_temp: Option<f32>,
    // water_temp: Option<f32>,
    location: Option<String>,
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
    dives: Vec<CsvBuilder>,
}

// Print in stdout the json representation of dive log.
pub fn to_json(path: &str) -> Result<(), Box<dyn Error>> {
    let mut rdr = ReaderBuilder::new()
        .quoting(false)
        .delimiter(b'"')
        .from_path(path)?;
    let mut vec = Vec::new();

    for result in rdr.deserialize() {
        let record: CsvBuilder = result?;
        vec.push(record);
    }

    let dives = CsvToJson { dives: vec };

    let json = serde_json::to_string(&dives)?;

    println!("{}", json);

    Ok(())
}

// Draw a simple plot of the average depth by location.
pub fn to_plot(path: &str) -> Result<(), Box<dyn Error>> {
    let mut rdr = ReaderBuilder::new()
        .quoting(false)
        .delimiter(b'"')
        .from_path(path)?;

    let mut x_axis = Vec::new();
    let mut y_axis = Vec::new();

    for x in rdr.deserialize() {
        let x_data: CsvBuilder = x?;

        x_axis.push(x_data.location.unwrap());
        y_axis.push(x_data.avg_depth.unwrap());
    }

    let trace = Bar::new(x_axis, y_axis).name("Depth by location");

    let layout = Layout::new()
        .title(Title::new("Depth by location"))
        .x_axis(Axis::new().title(Title::new("Location")))
        .y_axis(Axis::new().title(Title::new("Meters")));

    let mut plot = Plot::new();

    plot.add_trace(trace);
    plot.set_layout(layout);
    plot.show();

    Ok(())
}
