use openwater;
fn main() {
    let path = "examples/uddf/log.uddf";
    let open = openwater::uddf_parse_file(path);
    println!("{:#?}", open);
}
