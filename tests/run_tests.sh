#!/usr/bin/env bash
# Fail-closed, dependency-free entry point for Ninja Run's Godot test suite.
set -u

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PROJECT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
GODOT_BIN=${GODOT_BIN:-godot}
TIMEOUT_SECONDS=${NINJA_RUN_TEST_TIMEOUT_SECONDS:-90}
SUCCESS_MARKER='RESULT: 76 passed, 0 failed (76 scheduled, 76 executed)'

if command -v timeout >/dev/null 2>&1; then
  TIMEOUT_BIN=timeout
elif command -v gtimeout >/dev/null 2>&1; then
  TIMEOUT_BIN=gtimeout
else
  echo "ERROR: GNU timeout (or gtimeout) is required for fail-closed tests." >&2
  exit 2
fi

run_checked() {
  project_path=$1
  script_path=$2
  marker=$3
  work_dir=$(mktemp -d "${TMPDIR:-/tmp}/ninja-run-tests.XXXXXX") || return 2
  output_file="$work_dir/output.log"

  XDG_DATA_HOME="$work_dir/data" \
  XDG_CONFIG_HOME="$work_dir/config" \
  XDG_CACHE_HOME="$work_dir/cache" \
  "$TIMEOUT_BIN" "${TIMEOUT_SECONDS}s" "$GODOT_BIN" --headless \
    --log-file "$work_dir/godot.log" --path "$project_path" -s "$script_path" >"$output_file" 2>&1
  status=$?
  cat "$output_file"

  if [ "$status" -eq 124 ]; then
    echo "ERROR: test command timed out after ${TIMEOUT_SECONDS}s." >&2
    rm -rf "$work_dir"
    return 124
  fi
  if [ "$status" -ne 0 ]; then
    echo "ERROR: Godot exited with status $status." >&2
    rm -rf "$work_dir"
    return "$status"
  fi
  if grep -E 'SCRIPT ERROR:|Parse Error:|(^|[[:space:]])ERROR:' "$output_file" >/dev/null; then
    echo "ERROR: Godot reported an engine/script error." >&2
    rm -rf "$work_dir"
    return 1
  fi
  if ! grep -F -x "$marker" "$output_file" >/dev/null; then
    echo "ERROR: required successful completion marker was absent." >&2
    rm -rf "$work_dir"
    return 1
  fi
  rm -rf "$work_dir"
  return 0
}

run_self_check() {
  fixture_dir=$(mktemp -d "${TMPDIR:-/tmp}/ninja-run-wrapper-fixtures.XXXXXX") || return 2
  apply_fixture() {
    fixture_name=$1
    fixture_body=$2
    printf '%s\n' "$fixture_body" >"$fixture_dir/$fixture_name.gd"
  }

  apply_fixture declared_failure 'extends SceneTree
func _init() -> void:
	print("declared failure fixture")
	quit(1)'
  apply_fixture runtime_error "extends SceneTree
func _init() -> void:
	call_deferred(\"_fault\")
	create_timer(0.1).timeout.connect(func() -> void: quit(0))
func _fault() -> void:
	print(\"$SUCCESS_MARKER\")
	var absent: Node = null
	absent.get_name()
"
  apply_fixture parse_error 'extends SceneTree
func _init( -> void:
	quit(0)'
  apply_fixture hang 'extends SceneTree
func _init() -> void:
	while true:
		pass'

  for fixture in declared_failure runtime_error parse_error hang; do
    if NINJA_RUN_TEST_TIMEOUT_SECONDS=2 "$0" --check-script "$fixture_dir/$fixture.gd" --project "$PROJECT_DIR"; then
      echo "ERROR: wrapper accepted $fixture fixture." >&2
      rm -rf "$fixture_dir"
      return 1
    fi
    echo "WRAPPER SELF-CHECK rejected $fixture fixture"
  done
  rm -rf "$fixture_dir"
  echo "WRAPPER SELF-CHECK PASS"
}

if [ "${1:-}" = "--self-check" ]; then
  run_self_check
  exit $?
fi

if [ "${1:-}" = "--check-script" ]; then
  [ "$#" -eq 4 ] && [ "${3:-}" = "--project" ] || {
    echo "Usage: $0 --check-script SCRIPT --project PROJECT" >&2
    exit 2
  }
  run_checked "$4" "$2" "$SUCCESS_MARKER"
  exit $?
fi

[ "$#" -eq 0 ] || {
  echo "Usage: $0 [--self-check]" >&2
  exit 2
}
run_checked "$PROJECT_DIR" "$PROJECT_DIR/tests/test_runner.gd" "$SUCCESS_MARKER"
primary_status=$?
[ "$primary_status" -eq 0 ] || exit "$primary_status"
run_checked "$PROJECT_DIR" "$PROJECT_DIR/tests/integration_runner.gd" 'INTEGRATION RESULT: 62 passed, 0 failed (62 scheduled, 62 executed)'
integration_status=$?
[ "$integration_status" -eq 0 ] || exit "$integration_status"
run_checked "$PROJECT_DIR" "$PROJECT_DIR/tests/long_run_runner.gd" 'LONG-RUN RESULT: 3 passed, 0 failed (3 scheduled, 3 executed)'
