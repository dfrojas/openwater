use serde::Deserialize;

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

#[derive(Debug, Deserialize)]
struct GasDefinition {
    mix: Mix,
}

#[derive(Debug, Deserialize)]
struct Mix {
    name: String,
    o2: f32,
    n2: f32,
    he: f32,
}

#[derive(Debug, Deserialize)]
struct Geography {
    location: String,
    latitude: f32,
    longitude: f32,
}

#[derive(Debug, Deserialize)]
struct Site {
    name: String,
    geography: Geography,
}

#[derive(Debug, Deserialize)]
struct DiveSite {
    site: Site,
}

// TODO: Handle the cross-references: https://www.streit.cc/extern/uddf_v321/en/cross-referencing.html
// #[derive(Debug, Deserialize)]
// struct Link {
//     reference: String,
// }

#[derive(Debug, Deserialize)]
struct TankData {
    tankvolume: f32,
    tankpressurebegin: f32,
    tankpressureend: f32,
}

#[derive(Debug, Deserialize)]
struct InformationBeforeDive {
    tankdata: TankData,
    weatherconditions: WeatherConditions,
}

#[derive(Debug, Deserialize)]
struct WeatherConditions {
    airtemp: f32,
    watertemp: f32,
    visibility: f32,
}

#[derive(Debug, Deserialize)]
struct Samples {
    waypoint: Vec<Waypoint>,
}

#[derive(Debug, Deserialize)]
struct Waypoint {
    depth: f32,
    divetime: f32,
    temperature: f32,
    tankpressure: f32,
}

#[derive(Debug, Deserialize)]
struct InformationAfterDive {
    notes: String,
    rating: u8,
    visibility: f32,
    current: f32,
}

#[derive(Debug, Deserialize)]
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

#[derive(Debug, Deserialize)]
struct RepetitionGroup {
    dive: Dive,
}

#[derive(Debug, Deserialize)]
struct ProfileData {
    repetitiongroup: RepetitionGroup,
}

#[derive(Debug, Deserialize)]
pub struct UDDF {
    generator: Generator,
    diver: Diver,
    gasdefinitions: GasDefinition,
    divesite: DiveSite,
    profiledata: ProfileData,
}
