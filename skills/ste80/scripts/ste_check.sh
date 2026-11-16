#!/bin/sh
# ste_check.sh: heuristic linter for AI tells and STE-style English.
# It finds places to look at. It is not an AI detector and it does not prove
# compliance with ASD-STE100. It needs only a POSIX sh and awk.

usage() {
    cat <<'EOF'
Usage: ste_check.sh [--strict] FILE...

Flags AI tells and sentences that are not in STE style.

  FILE       a text or Markdown file, or - for standard input
  --strict   exact word limits and more word rules
  -h, --help show this help

Exit code: 0 if there are no findings, 1 if there are findings, 2 on a usage error.
EOF
}

strict=0
for arg do
    shift
    case $arg in
        --strict) strict=1 ;;
        -h | --help) usage; exit 0 ;;
        -?*) echo "ste_check: unknown option $arg" >&2; usage >&2; exit 2 ;;
        *) set -- "$@" "$arg" ;;
    esac
done
[ $# -gt 0 ] || { usage >&2; exit 2; }

dir=$(dirname "$0")
# STE_AWK selects another awk, for example "busybox awk". The tests use it.
# shellcheck disable=SC2086
check() { STE_FILE=$1 STE_STRICT=$strict LC_ALL=C ${STE_AWK:-awk} -f "$dir/ste_check.awk"; }

status=0
for f do
    if [ "$f" = - ]; then
        check -
    elif [ -r "$f" ] && [ ! -d "$f" ]; then
        # shellcheck disable=SC2094 # the first "$f" is only the name to print
        check "$f" <"$f"
    else
        echo "ste_check: cannot read $f" >&2
        exit 2
    fi
    rc=$?
    [ "$rc" -gt "$status" ] && status=$rc
done
exit "$status"
