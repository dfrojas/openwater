// use plotly::common::Title;
// use plotly::layout::{Axis, Layout};
// use plotly::{Bar, Plot};
use std::error::Error;

use serde_json::Value;

use openwater;

pub fn to_json(path: &str) -> Result<Value, Box<dyn Error>> {
    let uddf_parsed = openwater::uddf_parse_file(path)?;
    let json = serde_json::to_value(&uddf_parsed)?;
    Ok(json)
}

// // Draw a simple plot of the average depth by location.
// pub fn to_plot(path: &str) -> Result<(), Box<dyn Error>> {
//     let mut rdr = ReaderBuilder::new()
//         .quoting(false)
//         .delimiter(b'"')
//         .from_path(path)?;

//     let mut x_axis = Vec::new();
//     let mut y_axis = Vec::new();

//     for x in rdr.deserialize() {
//         let x_data: CsvBuilder = x?;

//         x_axis.push(x_data.location.unwrap());
//         y_axis.push(x_data.avg_depth.unwrap());
//     }

//     let trace = Bar::new(x_axis, y_axis).name("Depth by location");

//     let layout = Layout::new()
//         .title(Title::new("Depth by location"))
//         .x_axis(Axis::new().title(Title::new("Location")))
//         .y_axis(Axis::new().title(Title::new("Meters")));

//     let mut plot = Plot::new();

//     plot.add_trace(trace);
//     plot.set_layout(layout);
//     plot.show();

//     Ok(())
// }
