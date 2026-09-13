from pathlib import Path


state = Path("state.txt").read_text(encoding="utf-8").strip()
failed = state != "fixed"
target = '<testcase classname="generic.InvariantTest" name="target_stays_fixed">' + ("<failure/>" if failed else "") + "</testcase>"
control = '<testcase classname="generic.InvariantTest" name="control_confirms_fixed_state"/>' if not failed else ""
Path("reports").mkdir(exist_ok=True)
Path("reports/junit.xml").write_text(f"<testsuite>{target}{control}</testsuite>", encoding="utf-8")
raise SystemExit(1 if failed else 0)
