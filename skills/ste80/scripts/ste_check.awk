# ste_check.awk: heuristic linter for AI tells and STE-style English.
# Reads one text on standard input. Run it through ste_check.sh.
#
# Only POSIX awk that every implementation has (gawk, mawk, busybox, BWK/macOS):
# no \b, \w, {n,m}, [[:classes:]] or gawk functions. Word boundaries are checked
# on a lowercase copy of the line with a space added at each end.

function set(arr, list,   n, i, tmp) {
    n = split(list, tmp, " ")
    for (i = 1; i <= n; i++) arr[tmp[i]] = 1
}

function swaps(list,   n, i, p, tmp) {
    n = split(list, tmp, "|")
    for (i = 1; i <= n; i++) {
        p = index(tmp[i], "=")
        SWW[++nsw] = substr(tmp[i], 1, p - 1)
        SWA[nsw] = substr(tmp[i], p + 1)
    }
}

function tell(re, rule, msg) {
    TRE[++ntell] = re
    TRULE[ntell] = rule
    TMSG[ntell] = msg
}

BEGIN {
    strict = (ENVIRON["STE_STRICT"] == "1")
    SEP = "\001"
    W = "[a-z0-9_]"
    NW = "[^a-z0-9_]"
    WS = "[ \t]+"
    AUX = "(am|is|are|was|were|be|been|being)"

    PASSIVE = NW AUX WS "(" W "+ly" WS ")?" W "+(ed|en|wn|lt|nt|pt|ung|ade|one|ept|ought)" NW
    MODAL_PASSIVE = NW "(can|could|may|might|must|should|shall|will|would)" WS "(not" WS ")?be" WS W "+(ed|en)" NW
    PERFECT = NW "(has|have|had)" WS "(not" WS ")?(been|" W "+ed|" W "+en|done|made|gone|seen|run|set|put)" NW
    PROGRESSIVE = NW AUX WS "(not" WS ")?" W "+ing" NW
    ING_START = "^ " W "+ing" NW
    ING = "([.,;:]" WS "|" NW "(by|while|when|after|before)" WS ")" W "+ing" NW
    NOT_ONLY = NW "not" WS "(just|only|merely)" NW
    CONTRACTION = NW "(" W "+(n't|'re|'ve|'ll|'d|'m)|(it|that|there|what|here)'s)" NW
    NOUN_ONLY = NW "(check|test)(s|ed)?" WS "(the|a|an|that|if|your|all)" NW
    WORD = "[A-Za-z][A-Za-z'-]*|[0-9][A-Za-z0-9_.,:\\/%-]*"

    # Short working lists. They are not the ASD-STE100 dictionary.
    swaps("utilize=use|utilise=use|leverage=use|employ=use|perform=do|conduct=do|accomplish=do|facilitate=help, let")
    swaps("ensure=make sure|verify=make sure|commence=start|initiate=start|terminate=stop|eliminate=remove")
    swaps("modify=change|indicate=show|demonstrate=show|obtain=get|acquire=get|provide=give|assist=help")
    swaps("attempt=try|retain=keep|observe=monitor, see|locate=find|determine=find|subsequently=then")
    swaps("however=but|therefore=thus, as a result|hence=thus|furthermore=also|moreover=also|additionally=also")
    swaps("whereas=but|via=through|whether=if|numerous=many|adequate=sufficient|identical=same")
    swaps("simultaneously=at the same time|prior to=before|due to=because of|in order to=to|in the event that=if")
    swaps("it is important to note=(delete)|it's important to note=(delete)|it should be noted=(delete)")
    swaps("delve=examine|robust=strong, reliable|seamless=(delete)|seamlessly=(delete)|comprehensive=full")
    swaps("crucial=important|pivotal=important|landscape=field, area|realm=field, area|showcase=show")
    swaps("streamline=simplify|empower=let, help|harness=use|foster=help|underscore=show|game-changer=(delete)")
    swaps("tapestry=(delete)|testament=(delete) or say what it shows|elevate=improve|unlock=let, give")
    swaps("intricate=complex|meticulous=careful|vibrant=(delete)|enhance=improve|groundbreaking=(fact or delete)")
    swaps("cutting-edge=(fact or delete)|world-class=(fact or delete)|best-in-class=(fact or delete)")
    swaps("renowned=(fact or delete)|stunning=(delete)|breathtaking=(delete)|serves as=is|stands as=is|boasts=has")
    if (strict) {
        swaps("need=necessary (adj)|may=can|might=can|could=can|should=must|shall=must|would=will|since=because")
        swaps("both=the two|further=more|additional=more|acceptable=permitted|main=primary|portion=part")
        swaps("required=necessary|insert=put|rotate=turn|avoid=prevent|follow=obey|inspect=examine")
        swaps("e.g.=for example|i.e.=that is|etc.=and other")
    }

    nph = split("set up|find out|look into|look at|fill in|fill out|turn on|turn off|switch on|switch off|go through|point out|put together|take out|come up with|give up|carry out|figure out|check out|back up|shut down", PHRASAL, "|")

    set(ING_NOUN_OK, "during following opening remaining according something nothing anything everything thing things string strings bring ring spring king wing sing single logging caching routing testing debugging networking staging setting settings mapping warning warnings building meaning morning evening ceiling padding spacing rendering hosting tooling training pricing billing encoding streaming scheduling parsing linting formatting being missing existing incoming outgoing pending")
    set(NOT_PARTICIPLE, "different present absent current recent frequent silent independent efficient sufficient apparent consistent important relevant urgent evident excellent competent dependent transparent open even often golden hidden sudden wooden own down shown known unknown brown grown drawn built content intent event agent client point front want difficult")
    set(IMPERATIVE, "add apply attach click close configure connect copy create delete disconnect do download edit enter examine find get give install keep let make measure monitor move open push pull put read remove replace restart run select send set start stop turn type update upload use write if when before after to")

    tell(NW "(it'?s|it is|this is|that'?s|is)" WS "not" WS "(just|only|merely|simply|about)" NW, "not-x-but-y", "'not just X, but Y' framing: state the point")
    tell("", "not-x-but-y", "'not just X but Y' framing: state the point")  # see not_only_but()
    tell(NW "isn'?t" WS "(just" WS ")?about" NW, "not-x-but-y", "'this isn't about X' framing: state the point")
    tell("^ (great question|certainly|of course|sure|absolutely)[!,.]", "chatbot", "chatbot opener: delete")
    tell(NW "(i hope this helps|let me know if|would you like me to|feel free to|happy to help)" NW, "chatbot", "chatbot closer: delete")
    tell(NW "(let'?s (dive|delve|break (this|it) down|explore|unpack)|here'?s the thing|without further ado)" NW, "run-up", "run-up before the point: start with the point")
    tell(NW "(at its core|the real question is|fundamentally|at the end of the day)" NW, "fake-depth", "fake depth: say the plain claim")
    tell(NW "(let that sink in|and that changes everything|that'?s the real (win|story)|read that again)" NW, "closer", "dramatic closer: delete")
    tell(NW "(don'?t get me wrong|to be clear|one might be tempted)" NW, "strawman", "arguing with nobody: remove")
    tell(NW "(as of my (last|latest) (update|training)|based on (the )?available information)" NW, "knowledge-hedge", "knowledge-limit hedge: delete")
    tell(NW "in this (guide|article|section|post),? (we|i)('ll| will)" NW, "meta", "writing about the text: give the content")
    tell(NW "(could|may|might) (potentially|possibly|arguably)" NW, "stacked-hedge", "stacked hedge: keep one hedge")
    tell(NW "(experts|studies|many people|observers) (say|agree|show|believe|suggest)" NW, "vague-authority", "vague authority: name the source or delete")
    tell("," WS "(highlighting|underscoring|emphasizing|ensuring|reflecting|showcasing|fostering|cultivating|contributing to)" NW, "ing-rider", "shallow '-ing' rider: delete or make it a sentence")
    tell(NW "((plays|play|played) a (pivotal|crucial|key|vital) role|marks? a (significant|major) milestone|the future looks bright)" NW, "inflation", "inflated significance: say what happened")
    tell(NW "((is|are|was|were) associated with|in connection with|linked to|tied to)" NW, "vague-association", "vague connection: name the relation (founded, caused, part of)")
    tell(NW "(is|are|was|were|be)(" WS W "+ly)?" WS "(high-quality|well-known|well-documented|long-term|real-time|well-tested|client-facing)" NW, "hyphen-pair", "drop the hyphen after the noun ('is well documented')")
    tell("^ (that'?s|this is) (the real|why it|what) ", "closer", "possible one-line closer: cut it if it repeats the point")
}

# Findings stay sorted by line, then rule. Equal keys keep the order found.
function add(line, rule, msg,   i) {
    for (i = nf; i > 0 && (FL[i] > line || (FL[i] == line && (FR[i] "") > (rule ""))); i--) {
        FL[i + 1] = FL[i]; FR[i + 1] = FR[i]; FM[i + 1] = FM[i]
    }
    FL[i + 1] = line; FR[i + 1] = rule; FM[i + 1] = msg
    nf++
}

# [text](url) -> text
function unlink(s,   m, p) {
    while (match(s, /\[[^]]*\]\([^)]*\)/)) {
        m = substr(s, RSTART, RLENGTH)
        p = index(m, "](")
        s = substr(s, 1, RSTART - 1) substr(m, 2, p - 2) substr(s, RSTART + RLENGTH)
    }
    return s
}

function keep(s, n) {
    gsub(SEP, ".", s)
    sub(/^[ \t]+/, "", s)
    sub(/[ \t]+$/, "", s)
    if (s != "") SENT[++n] = s
    return n
}

# Splits a paragraph into SENT[1..n]. A period after an abbreviation does not end a sentence.
function split_sentences(p,   n, seg) {
    p = " " p
    while (match(p, /[^A-Za-z0-9_](e\.g|i\.e|etc|vs|Dr|Mr|Ms|No)\./)) {
        seg = substr(p, RSTART + 1, RLENGTH - 1)
        gsub(/\./, SEP, seg)
        p = substr(p, 1, RSTART) seg substr(p, RSTART + RLENGTH)
    }
    n = 0
    while (match(p, /[.!?:][ \t]+[A-Z0-9"'(]/)) {
        n = keep(substr(p, 1, RSTART), n)
        p = substr(p, RSTART + RLENGTH - 1)
    }
    return keep(p, n)
}

# Parentheses and quoted text count as one word. So does a number with its unit.
function count_words(s,   n, t, a, b, q, pc, num) {
    gsub(/\([^)]*\)/, " PAREN ", s)
    gsub(/"[^"]*"/, " QUOTE ", s)
    q = length("”")
    while ((a = index(s, "“")) && (b = index(substr(s, a + q), "”")))
        s = substr(s, 1, a - 1) " QUOTE " substr(s, a + q + b + q - 1)
    n = 0; num = 0; pc = " "
    while (match(s, WORD)) {
        if (RSTART > 1) pc = substr(s, RSTART - 1, 1)
        t = substr(s, RSTART, RLENGTH)
        s = substr(s, RSTART + RLENGTH)
        if (num && tolower(t) ~ /^(ms|s|kb|mb|gb|tb|px|kg|g|m|cm|mm|km|h|min)$/) {
            num = 0
        } else {
            n++
            num = (t ~ /^[0-9][0-9.,]*$/ && pc !~ /[A-Za-z0-9_]/)
        }
        pc = substr(t, length(t))
    }
    return n
}

function imperative(s) {
    return match(s, WORD) && (tolower(substr(s, RSTART, RLENGTH)) in IMPERATIVE)
}

function flush(   n, i, c, lim) {
    if (!plen) return
    n = split_sentences(para)
    npara++
    if (n > 6) add(pstart, "paragraph-length", n " sentences in one paragraph (max 6)")
    for (i = 1; i <= n; i++) {
        c = count_words(SENT[i])
        nsent++
        total += c
        if (c > maxw) maxw = c
        lim = imperative(SENT[i]) ? 20 : 25
        if (c > lim + (strict ? 0 : 3))
            add(pstart, "sentence-length", c " words (" (lim == 20 ? "instruction" : "description") " max " lim ")")
    }
    plen = 0
    para = ""
}

# Next match of re in the padded lowercase line. re must start and end with one
# boundary character. M gets the match in its original case, without them.
function next_match(re) {
    if (!match(REST, re)) return 0
    M = substr(ORIG, OFF + RSTART + 1, RLENGTH - 2)
    OFF += RSTART + RLENGTH - 2
    REST = substr(REST, RSTART + RLENGTH - 1)
    return 1
}

function start_scan(low) { REST = low; OFF = 0 }

function last_word(s) {
    s = tolower(s)
    sub(/^.*[^a-z0-9_]/, "", s)
    return s
}

# True if w is in s with no character of class cls directly before or after it.
function has_word(s, w, cls,   p, off) {
    off = 0
    while ((p = index(substr(s, off + 1), w)) > 0) {
        if (substr(s, off + p - 1, 1) !~ cls && substr(s, off + p + length(w), 1) !~ cls) return 1
        off += p
    }
    return 0
}

# "not only X but Y": "but" must start within 80 characters, in the same sentence.
function not_only_but(low,   rest, tail, p) {
    rest = low
    while (match(rest, NOT_ONLY)) {
        rest = substr(rest, RSTART + RLENGTH - 1)
        tail = rest
        if ((p = index(tail, ".")) > 0) tail = substr(tail, 1, p)
        if (match(tail, NW "but" NW) && RSTART <= 80) return 1
    }
    return 0
}

function ing_form(no, w,   lw) {
    lw = tolower(w)
    if (!(lw in ING_NOUN_OK) && length(lw) > 4) add(no, "ing-form", "'-ing' verb form: '" w "'")
}

function check_line(no, line, raw,   low, i) {
    low = " " tolower(line) " "
    ORIG = " " line " "

    if (index(line, ";")) add(no, "semicolon", "semicolon: write two sentences or a list")
    if (index(line, "—") || index(line, " -- ")) add(no, "dash", "em dash as sentence glue: use a period or colon")

    start_scan(low)
    while (next_match(PASSIVE))
        if (!(last_word(M) in NOT_PARTICIPLE)) add(no, "passive", "possible passive voice: '" M "'")
    start_scan(low)
    while (next_match(MODAL_PASSIVE)) add(no, "modal-passive", "modal + passive: '" M "'")
    start_scan(low)
    while (next_match(PERFECT)) add(no, "perfect-tense", "perfect tense: '" M "'")
    start_scan(low)
    while (next_match(PROGRESSIVE))
        if (!(last_word(M) in ING_NOUN_OK)) add(no, "progressive", "progressive tense: '" M "'")

    start_scan(low)
    if (match(low, ING_START)) {
        ing_form(no, substr(ORIG, 2, RLENGTH - 2))
        OFF = RLENGTH - 1
        REST = substr(low, OFF + 1)
    }
    while (next_match(ING)) {
        match(M, /[A-Za-z0-9_]+$/)
        ing_form(no, substr(M, RSTART))
    }

    for (i = 1; i <= nph; i++)
        if (has_word(low, PHRASAL[i], W)) add(no, "phrasal-verb", "phrasal verb '" PHRASAL[i] "'")

    for (i = 1; i <= ntell; i++)
        if (i == 2 ? not_only_but(low) : low ~ TRE[i]) add(no, TRULE[i], TMSG[i])

    if (index(raw, "“") || index(raw, "”") || index(raw, "‘") || index(raw, "’"))
        add(no, "curly-quotes", "curly quotes: use straight quotes in Markdown and code")

    if (strict) {
        if (low ~ CONTRACTION) add(no, "contraction", "contraction (not permitted in strict mode)")
        if (low ~ NOUN_ONLY) add(no, "noun-only", "'check'/'test' used as a verb (STE: noun only)")
    }
    for (i = 1; i <= nsw; i++)
        if (has_word(low, SWW[i], "[a-z0-9_-]")) add(no, "word", "'" SWW[i] "' -> " SWA[i])
}

# Main loop: keep prose only. Skip front matter, code blocks, tables and indented code.
{
    raw = $0
    sub(/\r$/, "", raw)
    line = raw
    sub(/[ \t]+$/, "", line)
    t = line
    sub(/^[ \t]+/, "", t)

    if (NR == 1 && t == "---") { front = 1; next }
    if (front) { if (t == "---") front = 0; next }
    if (substr(t, 1, 3) == "```" || substr(t, 1, 3) == "~~~") { code = !code; next }
    if (code || substr(t, 1, 1) == "|" || substr(line, 1, 4) == "    ") { flush(); next }

    gsub(/`[^`]*`/, "CODE", line)
    line = unlink(line)
    gsub(/https?:\/\/[^ \t]+/, "URL", line)
    if (line ~ /^[ \t]*([-*+]|[0-9]+[.)])[ \t]+/) {
        flush()
        sub(/^[ \t]*([-*+]|[0-9]+[.)])[ \t]+/, "", line)
    }
    sub(/^[ \t]*>[ \t]?/, "", line)
    sub(/^#+[ \t]+/, "", line)
    gsub(/[*_]/, "", line)

    if (line !~ /[^ \t]/) { flush(); next }

    t = line
    sub(/^[ \t]+/, "", t)
    sub(/[ \t]+$/, "", t)
    if (!plen++) { pstart = NR; para = t } else para = para " " t
    check_line(NR, line, raw)
}

END {
    flush()
    printf "%s: %d finding(s) | %d sentences, avg %.1f words, max %d\n", ENVIRON["STE_FILE"], nf, nsent, total / (nsent ? nsent : 1), maxw
    for (i = 1; i <= nf; i++) printf "  %4d  %-16s %s\n", FL[i], FR[i], FM[i]
    exit (nf > 0)
}
