use serde::{Deserialize, Serialize};

#[derive(Debug, Deserialize, Serialize)]
pub struct Generator {
    pub name: String,
    pub version: String,
    pub date: String,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct Diver {
    pub owner: Owner,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct Owner {
    pub personal: Personal,
    pub contact: Contact,
    pub equipment: Equipment,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct Personal {
    pub firstname: String,
    pub lastname: String,
    pub birthday: String,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct Contact {
    pub email: String,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct Equipment {
    pub divecomputer: DiveComputer,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct DiveComputer {
    pub name: String,
    pub serialnumber: String,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct GasDefinition {
    pub mix: Mix,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct Mix {
    pub name: String,
    pub o2: f32,
    pub n2: f32,
    pub he: f32,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct Geography {
    pub location: String,
    pub latitude: f32,
    pub longitude: f32,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct Site {
    pub name: String,
    pub geography: Geography,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct DiveSite {
    pub site: Site,
}

// TODO: Handle the cross-references: https://www.streit.cc/extern/uddf_v321/en/cross-referencing.html
// #[derive(Debug, Deserialize)]
// struct Link {
//     reference: String,
// }

#[derive(Debug, Deserialize, Serialize)]
pub struct TankData {
    pub tankvolume: f32,
    pub tankpressurebegin: f32,
    pub tankpressureend: f32,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct InformationBeforeDive {
    pub tankdata: TankData,
    pub weatherconditions: WeatherConditions,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct WeatherConditions {
    pub airtemp: f32,
    pub watertemp: f32,
    pub visibility: f32,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct Samples {
    pub waypoint: Vec<Waypoint>,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct Waypoint {
    pub depth: f32,
    pub divetime: f32,
    pub temperature: f32,
    pub tankpressure: f32,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct InformationAfterDive {
    pub notes: String,
    pub rating: u8,
    pub visibility: f32,
    pub current: f32,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct Dive {
    pub informationbeforedive: InformationBeforeDive,
    pub datetime: String,
    pub surfaceinterval: f32,
    pub greatestdepth: f32,
    pub averagedepth: f32,
    pub diveduration: f32,
    pub temperature: f32,
    pub samples: Samples,
    pub informationafterdive: InformationAfterDive,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct RepetitionGroup {
    pub dive: Dive,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct ProfileData {
    pub repetitiongroup: RepetitionGroup,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct UDDF {
    pub generator: Generator,
    pub diver: Diver,
    pub gasdefinitions: GasDefinition,
    pub divesite: DiveSite,
    pub profiledata: ProfileData,
}
