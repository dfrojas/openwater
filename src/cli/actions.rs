use plotly::common::Title;
use plotly::layout::{Axis, Layout};
use plotly::{Bar, Plot};
use std::error::Error;

use serde_json::Value;

use openwater;

pub fn to_json(path: &str) -> Result<Value, Box<dyn Error>> {
    let uddf_parsed = openwater::uddf_parse_file(path)?;
    let json = serde_json::to_value(&uddf_parsed)?;
    Ok(json)
}

// TODO: Max depth by location
pub fn to_plot(path: &str) -> Result<Value, Box<dyn Error>> {
    let uddf_parsed = openwater::uddf_parse_file(path)?;

    let mut x_axis: Vec<f32> = Vec::new();
    let mut y_axis: Vec<f32> = Vec::new();

    for waypoint in uddf_parsed
        .profiledata
        .repetitiongroup
        .dive
        .samples
        .waypoint
    {
        x_axis.push(waypoint.depth);
        y_axis.push(waypoint.tankpressure);
    }

    let trace = Bar::new(x_axis, y_axis).name("Depth");

    let layout = Layout::new()
        .title(Title::new("Tank Pressure by depth"))
        .x_axis(Axis::new().title(Title::new("Meters")))
        .y_axis(Axis::new().title(Title::new("Tank Pressure")));

    let mut plot = Plot::new();

    plot.add_trace(trace);
    plot.set_layout(layout);
    plot.show();

    Ok(Value::Null)
}
