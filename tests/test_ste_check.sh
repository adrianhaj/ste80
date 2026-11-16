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

finds() { # pattern in the output, text for standard input, checker options...
    pattern=$1 text=$2
    shift 2
    printf '%s\n' "$text" | check "$@" - | grep -q -- "$pattern"
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

finds "not-x-but-y" "It’s not just a cache." && finds "contraction" "It isn’t safe." --strict
ok "curly apostrophes match like straight ones" $?

finds "'leverages' -> use" "It leverages Redis." && finds "'utilizing' -> use" "We are utilizing it." &&
    finds "'verified' -> make sure" "We verified it." && exits_on 0 "The employee left through the main hall." &&
    finds "'follow' -> obey" "Follow the steps." --strict && exits_on 0 "Following the restart, logging is on." --strict
ok "word rules match inflected forms" $?

finds '^ *2  sentence-length .*: Run the import, then wait \.\.\.$' 'Short one.
Run the import, then wait until every row from the old table is in the new table and the two counts agree with the report that the tool prints.'
ok "a long sentence is reported with its own line and first words" $?

exits_on 0 '## Install the thing
Run the import, then wait until every row from the old table is in the new table and the counts agree now.'
ok "a heading is not part of the next sentence" $?

finds ' 3 sentences' "Read the docs at https://example.com/docs. Then run the tool. Then stop."
ok "a URL does not take the period that ends the sentence" $?

finds "dash" "The pump is open – the valve is shut." && exits_on 0 "It takes 10–15 minutes."
ok "a spaced en dash is a dash, a number range is not" $?

finds "not-x-but-y" "This doesn't mean tests are optional. It means the linter runs first." &&
    finds "clipped-tail" "The form fills in your address, no typing." && exits_on 0 "The form needs no typing."
ok "a contrast across two sentences and a clipped tail are flagged" $?

finds "fragments" "No setup. No config. No waiting." && finds "fragments" "We ship every. single. day." &&
    exits_on 0 "The tool needs no setup. Start it now."
ok "a row of fragments is flagged" $?

finds "closer" "That distinction matters." && finds "run-up" "Here's what you need to know." &&
    finds "run-up" "Is it fast? Honestly? It depends." && finds "run-up" "Here's the kicker." &&
    finds "fake-depth" "Observability is the language of trust." && finds "strawman" "I'm not saying it is slow." &&
    finds "strawman" "You might think it is slow." && finds "strawman" "A tempting approach would be to wait." &&
    finds "summary" "In conclusion, the tool works."
ok "more staging phrases of the skill are flagged" $?

finds "stacked-hedge" "In some cases it may fail." && finds "inflation" "It reflects a broader shift." &&
    finds "inflation" "It has a lasting legacy." && finds "vague-authority" "Experts argue that it works." &&
    finds "vague-authority" "Industry reports show growth." && finds "chatbot" "Let me know." &&
    finds "knowledge-hedge" "Details are limited." && finds "meta" "The table below compares the options."
ok "more inflation, authority and leftover phrases of the skill are flagged" $?

finds "'garnered' -> get" "It garnered support." && finds "'bolstered' -> support" "It bolstered trust." &&
    finds "'deep dive'" "This is a deep dive." && finds "'interplay'" "The interplay is new." &&
    finds "'quietly'" "It quietly grew." && finds "'enduring'" "It has enduring value." &&
    finds "'aligns with'" "It aligns with the plan."
ok "the other AI words of the skill are flagged" $?

finds "repeated-opening" "It reads the config. It checks the schema. It starts the server." &&
    exits_on 0 "It reads the config. Then it checks the schema. It starts the server."
ok "three sentences in a row that start with the same pronoun are flagged" $?

finds "rhythm" "The cat sat on the mat today. The dog ran to the park now. The bird flew over the big tree. The fish swam in the cold pond." &&
    exits_on 0 "The cat sat on the mat. The dog ran to the park and then came home again. The bird flew away. The fish swam in the cold pond all day."
ok "four sentences in a row of the same length are flagged" $?

finds "bold-label" '- **Speed:** It is fast.
- **Safety:** It is safe.
- **Cost:** It is cheap.' && exits_on 0 '- **Speed:** It is fast.
- It is safe.'
ok "a bold label on three list items in a row is flagged" $?

finds "heading-style" "## Getting Started With The Tool" && finds "heading-style" "## Install the tool →" &&
    finds "emoji" "## 🚀 Install the tool" && finds "emoji" "✅ It is fast." && exits_on 0 "## Install the tool"
ok "Title Case, arrows and emoji as decoration are flagged" $?

# shellcheck disable=SC2016
finds "tool-residue" "See https://example.com/a?utm_source=chatgpt.com for more." &&
    finds "tool-residue" "Dear [Your Name], thank you." &&
    finds "tool-residue" "It is fast. :contentReference[oaicite:0]{index=0}" &&
    exits_on 0 'The link has `utm_source=chatgpt.com` in it.' &&
    exits_on 0 "See [your guide](https://example.com/g) first."
ok "chatbot link tags, placeholders and citation marks are flagged" $?

cat tests/fixtures/clean.md | check /dev/stdin >/dev/null 2>&1
ok "a file that is not a regular file can be read" $?

exits 2
ok "no file is a usage error" $?

exits 2 --nope tests/fixtures/clean.md
ok "an unknown option is a usage error" $?

exits 2 tests/fixtures/no-such-file.md
ok "a missing file is a usage error" $?

check --help | grep -q '^Usage:'
ok "--help prints the usage" $?

exit "$fail"
