#!/bin/sh
# Tests for the checker. Run: sh tests/test_ste_check.sh
# STE_AWK selects the awk under test, for example STE_AWK="busybox awk".
# shellcheck disable=SC2319 # ok() reads the status of the test condition on purpose

cd "$(dirname "$0")/.." || exit 1
fail=0

check() { sh skills/ste80/scripts/ste_check.sh "$@"; }

ok() { # description, status of the test command
    if [ "$2" -eq 0 ]; then echo "ok   $1"; else echo "FAIL $1"; fail=1; fi
}

exits() { # expected exit code, checker arguments...
    want=$1
    shift
    check "$@" >/dev/null 2>&1
    [ $? -eq "$want" ]
}

exits_on() { # expected exit code, text for standard input, checker options...
    want=$1 text=$2
    shift 2
    printf '%s\n' "$text" | check "$@" - >/dev/null 2>&1
    [ $? -eq "$want" ]
}

check tests/fixtures/sample.md | diff tests/expected/sample.txt -
ok "fixture gives the expected findings" $?

check --strict tests/fixtures/sample.md | diff tests/expected/sample.strict.txt -
ok "fixture gives the expected findings in strict mode" $?

[ "$(awk '{ printf "%s\r\n", $0 }' tests/fixtures/sample.md | check - | sed 1d)" = "$(sed 1d tests/expected/sample.txt)" ]
ok "CRLF line ends give the same findings" $?

[ "$(: | check -)" = "-: 0 finding(s) | 0 sentences, avg 0.0 words, max 0" ]
ok "empty input has no findings" $?

exits 0 tests/fixtures/clean.md
ok "clean file exits 0" $?

exits 1 tests/fixtures/sample.md tests/fixtures/clean.md
ok "findings in one of two files exit 1" $?

[ "$(check tests/fixtures/clean.md tests/fixtures/clean.md | grep -c 'finding(s)')" -eq 2 ]
ok "each file gets a summary line" $?

exits_on 1 "It is important to note that the token is validated by the gateway."
ok "a known bad sentence exits 1" $?

exits_on 0 "You may check the valve." && exits_on 1 "You may check the valve." --strict
ok "strict mode adds word rules" $?

# shellcheck disable=SC2016
exits_on 0 'Run `rm -rf build; make` and read https://example.com/a;b first.'
ok "code and URLs are not prose" $?

exits 2
ok "no file is a usage error" $?

exits 2 --nope tests/fixtures/clean.md
ok "an unknown option is a usage error" $?

exits 2 tests/fixtures/no-such-file.md
ok "a missing file is a usage error" $?

check --help | grep -q '^Usage:'
ok "--help prints the usage" $?

exit "$fail"
