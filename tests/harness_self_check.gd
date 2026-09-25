extends SceneTree
## Standalone fail-closed verification for the test-runner bookkeeping contract.

const Harness = preload("res://scripts/core/foundation_test_harness.gd")

func _init() -> void:
	var passing = Harness.new()
	passing.schedule()
	passing.record("passing_fixture", "")
	var failing = Harness.new()
	failing.schedule()
	failing.record("failing_fixture", "intentional")
	var missing = Harness.new()
	missing.schedule()
	var parse_failure = Harness.new()
	parse_failure.record_external_failure("simulated parse failure")
	var valid := passing.exit_code() == 0 and failing.exit_code() != 0 and missing.exit_code() != 0 and parse_failure.exit_code() != 0
	print("HARNESS SELF-CHECK %s" % ("PASS" if valid else "FAIL"))
	quit(0 if valid else 1)
