use openwater;
fn main() {
    let path = "examples/uddf/log.uddf";
    let open = openwater::parse_uddf_file(path);
    println!("{:#?}", open);
}
