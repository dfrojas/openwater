use openwater;

fn main() {
    let path = "/Users/diegorojas/Documents/oss/openwater/examples/uddf/log.uddf";
    let open = openwater::parse_uddf_file(path);
    println!("{:#?}", open);

}
