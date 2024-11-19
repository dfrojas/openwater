use std::ffi::CString;
use std::os::raw::c_char;

#[no_mangle]
pub extern "C" fn openwater_init() -> *const c_char {
    let message = "Hello Diego from Rust!";
    let c_str = CString::new(message).unwrap();
    c_str.into_raw() as *const c_char
}
