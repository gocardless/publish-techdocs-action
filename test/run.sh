#!/bin/bash
# Regression tests for https://hackerone.com/reports/4012368. A stub stands in
# for techdocs-cli, so neither Docker nor a real publisher is needed.
#
# Usage: test/run.sh
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd -P)
# FAKE KEY
cred='eyJwcml2YXRlX2tleSI6IlNZTlRIRVRJQy1OT1QtQS1SRUFMLUtFWSJ9'
workdir=$(mktemp -d)
trap 'rm -rf "$workdir"' EXIT
failures=0

# Runs main.sh against a freshly built source tree; sets $status and $log.
run_case() {
  local name=$1 dir=$workdir/$1
  mkdir -p "$dir/bin" "$dir/workspace/docs"
  echo '# Docs' > "$dir/workspace/docs/index.md"
  printf 'site_name: %s\nmarkdown_extensions:\n  - pymdownx.snippets\n' "$name" \
    > "$dir/workspace/mkdocs.yml"

  case $name in
    # A symlink that stays inside the source tree is legitimate.
    contained) ln -s index.md "$dir/workspace/docs/alias.md";;
    # The reported exploit: a source-root symlink out of the tree, which
    # `--8<-- "proc/1/cmdline"` in a page then reads.
    escaping) ln -s /proc "$dir/workspace/proc";;
  esac

  cat > "$dir/bin/techdocs-cli" <<STUB
#!/bin/bash
echo "\$1" >> "\$STUB_LOG"
[[ \$1 == generate ]] || exit 0
env | grep -qF -- '$cred' && echo credential-in-environment >> "\$STUB_LOG"
ps -o args= -p "\$PPID" | grep -qF -- '$cred' && echo credential-in-parent-argv >> "\$STUB_LOG"
mkdir -p "\$GITHUB_WORKSPACE/site" && echo ok > "\$GITHUB_WORKSPACE/site/index.html"
STUB
  chmod +x "$dir/bin/techdocs-cli"

  : > "$dir/log"
  status=0
  env -i PATH="$dir/bin:/usr/bin:/bin" HOME="$dir" STUB_LOG="$dir/log" \
    GITHUB_WORKSPACE="$dir/workspace" \
    INPUT_PUBLISHER=googleGcs INPUT_CREDENTIALS="$cred" INPUT_BUCKET=bucket \
    INPUT_ENTITY=default/Component/test INPUT_SOURCEDIR=. \
    bash "$repo/main.sh" > "$dir/out" 2>&1 || status=$?
  log=$(cat "$dir/log")
}

check() {
  if [[ $2 == "$3" ]]; then
    echo "  PASS: $1"
  else
    echo "  FAIL: $1 (expected '$3', got '$2')"
    failures=$((failures + 1))
  fi
}

echo "clean source tree builds and publishes, with no credential reachable"
run_case clean
check "exits successfully" "$status" 0
check "generates and publishes" "$log" "$(printf 'generate\npublish')"

echo "symlink contained in the source tree still builds"
run_case contained
check "exits successfully" "$status" 0

echo "source-root symlink escaping the source tree is rejected"
run_case escaping
check "fails closed" "$status" 1
check "never generates or publishes" "$log" ""

(( failures == 0 )) || { echo "$failures check(s) failed"; exit 1; }
echo "all checks passed"
