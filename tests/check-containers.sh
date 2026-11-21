#!/bin/bash
set -euo pipefail

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
test_dir=$(mktemp -d)
trap 'rm -r "$test_dir"' EXIT
export COLIMA_HOME="$test_dir/colima"
export CONTAINER_COMMANDS="$test_dir/commands"
mkdir -p "$test_dir/bin" "$COLIMA_HOME/default"

cat > "$test_dir/bin/docker" <<'STUB'
#!/bin/bash
printf 'docker %s\n' "$*" >> "$CONTAINER_COMMANDS"
case "$*" in
  'context show') printf '%s\n' "$TEST_DOCKER_CONTEXT" ;;
  "info --format {{.ServerVersion}}") exit "$TEST_DOCKER_EXIT" ;;
  *) exit 99 ;;
esac
STUB

cat > "$test_dir/bin/colima" <<'STUB'
#!/bin/bash
printf 'colima %s\n' "$*" >> "$CONTAINER_COMMANDS"
[[ "$*" == 'status --profile default' ]] || exit 99
exit "$TEST_COLIMA_EXIT"
STUB

chmod +x "$test_dir/bin/docker" "$test_dir/bin/colima"
export PATH="$test_dir/bin:$PATH"
unset DOCKER_HOST DOCKER_CONTEXT

check_report() {
  local context=$1 engine_exit=$2 colima_exit=$3 expected_engine=$4 expected_colima=$5
  local report
  : > "$CONTAINER_COMMANDS"
  report=$(TEST_DOCKER_CONTEXT="$context" TEST_DOCKER_EXIT="$engine_exit" \
    TEST_COLIMA_EXIT="$colima_exit" /bin/bash "$repo_dir/bootstrap.sh" --check-containers)
  [[ "$report" == "Docker context: $context"$'\n'"Docker engine: $expected_engine"$'\n'"Colima (default profile): $expected_colima" ]]
  [[ "$(cat "$CONTAINER_COMMANDS")" == $'docker context show\ndocker info --format {{.ServerVersion}}\ncolima status --profile default' ]]
}

check_report colima 0 0 reachable running
check_report colima 1 1 unreachable 'not running or status unavailable'
check_report remote 0 1 reachable 'not running or status unavailable'
printf '%s\n' 'Container status scenarios passed.'
