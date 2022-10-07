use assert_fs::prelude::*;
use assert_cmd::Command;

#[test]
fn read_cressi_leonardo() -> Result<(), Box<dyn std::error::Error>> {
    let file = assert_fs::NamedTempFile::new("leonardoCressiSample.txt")?;
    file.write_str("Max Depth: 300")?;

    let mut cmd = Command::cargo_bin("openwater")?;
    cmd.arg("test").arg(file.path());
    cmd.assert()
        .success()
        .stdout(predicates::str::contains("Max Depth: 300"));

    Ok(())
}
