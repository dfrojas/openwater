#[derive(Hash, Eq, PartialEq, Debug)]
pub struct CressiLeonardo;

#[derive(Hash, Eq, PartialEq, Debug)]
pub struct MaresGenius;

pub trait BaseVendor {
    fn run(&self);
}

impl BaseVendor for MaresGenius {
    fn run(&self) {
    }
}

impl BaseVendor for CressiLeonardo {
    fn run(&self) {
    }
}
