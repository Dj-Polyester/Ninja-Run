class_name FoundationTestHarness
extends RefCounted
## Fail-closed bookkeeping shared by the executable test runner and its self-check.

var scheduled: int = 0
var executed: int = 0
var failures: Array[String] = []

func schedule() -> void:
	scheduled += 1

func record(name: String, failure: String) -> void:
	executed += 1
	if not failure.is_empty():
		failures.append("%s: %s" % [name, failure])

func record_external_failure(description: String) -> void:
	failures.append(description)

func succeeded() -> bool:
	return scheduled == executed and failures.is_empty()

func exit_code() -> int:
	return 0 if succeeded() else 1
