#[derive(Hash, Eq, PartialEq, Debug)]
pub struct CressiLeonardo{
    pub path: String,
}

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
    
        let path = self.path.clone();
        println!("{}", path);

    }
}
