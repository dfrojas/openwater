use assert_cmd::Command;

#[test]
fn json_outout_from_log_file() -> Result<(), Box<dyn std::error::Error>> {

    let mut cmd = Command::cargo_bin("openwater")?;
    cmd.arg("-i").arg("tests/fixtures/mocked_log.txt").arg("-o").arg("json");

    cmd.assert().success().stdout(predicates::str::contains("[{\"dive_number\":\"1\",\"duration\":\"45:00\",\"buddy\":\"Tom\"}]\n"));

    Ok(())

}
