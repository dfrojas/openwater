use serde::{Deserialize, Serialize};

#[derive(Debug, Deserialize, Serialize)]
struct Generator {
    name: String,
    version: String,
    date: String,
}

#[derive(Debug, Deserialize, Serialize)]
struct Diver {
    owner: Owner,
}

#[derive(Debug, Deserialize, Serialize)]
struct Owner {
    personal: Personal,
    contact: Contact,
    equipment: Equipment,
}

#[derive(Debug, Deserialize, Serialize)]
struct Personal {
    firstname: String,
    lastname: String,
    birthday: String,
}

#[derive(Debug, Deserialize, Serialize)]
struct Contact {
    email: String,
}

#[derive(Debug, Deserialize, Serialize)]
struct Equipment {
    divecomputer: DiveComputer,
}

#[derive(Debug, Deserialize, Serialize)]
struct DiveComputer {
    name: String,
    serialnumber: String,
}

#[derive(Debug, Deserialize, Serialize)]
struct GasDefinition {
    mix: Mix,
}

#[derive(Debug, Deserialize, Serialize)]
struct Mix {
    name: String,
    o2: f32,
    n2: f32,
    he: f32,
}

#[derive(Debug, Deserialize, Serialize)]
struct Geography {
    location: String,
    latitude: f32,
    longitude: f32,
}

#[derive(Debug, Deserialize, Serialize)]
struct Site {
    name: String,
    geography: Geography,
}

#[derive(Debug, Deserialize, Serialize)]
struct DiveSite {
    site: Site,
}

// TODO: Handle the cross-references: https://www.streit.cc/extern/uddf_v321/en/cross-referencing.html
// #[derive(Debug, Deserialize)]
// struct Link {
//     reference: String,
// }

#[derive(Debug, Deserialize, Serialize)]
struct TankData {
    tankvolume: f32,
    tankpressurebegin: f32,
    tankpressureend: f32,
}

#[derive(Debug, Deserialize, Serialize)]
struct InformationBeforeDive {
    tankdata: TankData,
    weatherconditions: WeatherConditions,
}

#[derive(Debug, Deserialize, Serialize)]
struct WeatherConditions {
    airtemp: f32,
    watertemp: f32,
    visibility: f32,
}

#[derive(Debug, Deserialize, Serialize)]
struct Samples {
    waypoint: Vec<Waypoint>,
}

#[derive(Debug, Deserialize, Serialize)]
struct Waypoint {
    depth: f32,
    divetime: f32,
    temperature: f32,
    tankpressure: f32,
}

#[derive(Debug, Deserialize, Serialize)]
struct InformationAfterDive {
    notes: String,
    rating: u8,
    visibility: f32,
    current: f32,
}

#[derive(Debug, Deserialize, Serialize)]
struct Dive {
    informationbeforedive: InformationBeforeDive,
    datetime: String,
    surfaceinterval: f32,
    greatestdepth: f32,
    averagedepth: f32,
    diveduration: f32,
    temperature: f32,
    samples: Samples,
    informationafterdive: InformationAfterDive,
}

#[derive(Debug, Deserialize, Serialize)]
struct RepetitionGroup {
    dive: Dive,
}

#[derive(Debug, Deserialize, Serialize)]
struct ProfileData {
    repetitiongroup: RepetitionGroup,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct UDDF {
    generator: Generator,
    diver: Diver,
    gasdefinitions: GasDefinition,
    divesite: DiveSite,
    profiledata: ProfileData,
}
