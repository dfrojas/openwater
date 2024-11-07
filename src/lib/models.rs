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
pub struct UDDF {
    #[serde(rename = "generator")]
    generator: Generator,
    #[serde(rename = "diver")]
    diver: Diver,
}
