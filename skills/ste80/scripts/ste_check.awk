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

# A single word of four letters or more also matches with a verb or plural
# ending: use, uses, used, using; verify, verifies, verified, verifying.
# The strict list is exact: its short common words give too many false matches.
function swaps(list, exact,   n, i, p, w, tmp) {
    n = split(list, tmp, "|")
    for (i = 1; i <= n; i++) {
        p = index(tmp[i], "=")
        w = substr(tmp[i], 1, p - 1)
        SWA[++nsw] = substr(tmp[i], p + 1)
        if (exact || w !~ /^[a-z][a-z][a-z][a-z]+$/) { SWW[nsw] = w; SWE[nsw] = "^" HY }
        else if (w ~ /e$/) { SWW[nsw] = substr(w, 1, length(w) - 1); SWE[nsw] = "^(e|es|ed|ing)" HY }
        else if (w ~ /[^aeiou]y$/) { SWW[nsw] = substr(w, 1, length(w) - 1); SWE[nsw] = "^(y|ies|ied|ying)" HY }
        else { SWW[nsw] = w; SWE[nsw] = "^(s|es|ed|ing)?" HY }
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
    HY = "[^a-z0-9_-]"
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
    swaps("functions as=is|operates as=is|bolster=support|garner=get|interplay=(say how the two affect each other)")
    swaps("quietly=(delete, unless it is about sound)|enduring=lasting, or delete|deep dive=look, review")
    swaps("align with=agree with, match|aligns with=agrees with, matches|aligned with=agreed with, matched")
    if (strict) {
        swaps("need=necessary (adj)|may=can|might=can|could=can|should=must|shall=must|would=will|since=because", 1)
        swaps("both=the two|further=more|additional=more|acceptable=permitted|main=primary|portion=part", 1)
        swaps("required=necessary|insert=put|rotate=turn|avoid=prevent|follow=obey|inspect=examine", 1)
        swaps("e.g.=for example|i.e.=that is|etc.=and other", 1)
    }

    nph = split("set up|find out|look into|look at|fill in|fill out|turn on|turn off|switch on|switch off|go through|point out|put together|take out|come up with|give up|carry out|figure out|check out|back up|shut down", PHRASAL, "|")

    set(ING_NOUN_OK, "during following opening remaining according something nothing anything everything thing things string strings bring ring spring king wing sing single logging caching routing testing debugging networking staging setting settings mapping warning warnings building meaning morning evening ceiling padding spacing rendering hosting tooling training pricing billing encoding streaming scheduling parsing linting formatting being missing existing incoming outgoing pending")
    set(NOT_PARTICIPLE, "different present absent current recent frequent silent independent efficient sufficient apparent consistent important relevant urgent evident excellent competent dependent transparent open even often golden hidden sudden wooden own down shown known unknown brown grown drawn built content intent event agent client point front want difficult")
    set(IMPERATIVE, "add apply attach click close configure connect copy create delete disconnect do download edit enter examine find get give install keep let make measure monitor move open push pull put read remove replace restart run select send set start stop turn type update upload use write if when before after to")
    set(PRONOUN, "it this he she they we i you")
    # ponytail: a short list of the emoji that chatbots use most, not all emoji. LC_ALL=C has no class for them.
    ndecor = split("🚀 ✅ 💡 🙏 👇 👉 ✨ 🔥 📌 🎯 ⚡ ⭐ 🎉 ❌", DECOR, " ")

    tell(NW "(it'?s|it is|this is|that'?s|is)" WS "not" WS "(just|only|merely|simply|about)" NW, "not-x-but-y", "'not just X, but Y' framing: state the point")
    tell("", "not-x-but-y", "'not just X but Y' framing: state the point")  # no pattern: see not_only_but()
    tell(NW "isn'?t" WS "(just" WS ")?about" NW, "not-x-but-y", "'this isn't about X' framing: state the point")
    tell(NW "(doesn'?t|does not)" WS "mean" NW ".*[.]" WS "(it|this|that)" WS "means" NW, "not-x-but-y", "contrast split across two sentences: state the point")
    tell("," WS "no" WS W "+[.!] ", "clipped-tail", "clipped negative tail (', no guessing'): write the full clause")
    tell(NW "no" WS W "+(" WS W "+)?[.!]" WS "no" NW, "fragments", "row of fragments: write one sentence with a claim")
    tell(NW W "+[.]" WS W "+[.]" WS W "+[.]", "fragments", "one word per sentence for emphasis: write one sentence")
    tell("^ (great question|certainly|of course|sure|absolutely)[!,.]", "chatbot", "chatbot opener: delete")
    tell(NW "(i hope this helps|let me know|would you like me to|want me to|should i continue|you'?re absolutely right|feel free to|happy to help)" NW, "chatbot", "chatbot closer: delete")
    tell(NW "(let'?s (dive|delve|break (this|it) down|explore|unpack|be honest)|here'?s (the thing|the kicker|what you need to know)|real talk|without further ado)" NW, "run-up", "run-up before the point: start with the point")
    tell(NW "honestly[?]", "run-up", "run-up before the point: start with the point")
    tell(NW "(at its core|the real question is|fundamentally|at the end of the day|the heart of the matter|is the (language|currency|architecture) of)" NW, "fake-depth", "fake depth: say the plain claim")
    tell(NW "(let that sink in|and that changes everything|that'?s the real (win|story)|read that again|that distinction matters)" NW, "closer", "dramatic closer: delete")
    tell("^ (in conclusion|in summary|to sum up|to summarize),", "summary", "signposted summary: cut it if it repeats the text")
    tell(NW "(don'?t get me wrong|to be clear|one might be tempted|i'?m not saying|i am not saying|this is not to say|a tempting approach would be|you might think|some might say)" NW, "strawman", "arguing with nobody: remove")
    tell(NW "(as of my (last|latest) (update|training)|based on (the )?available information|details are limited|it is believed that|maintains a low profile)" NW, "knowledge-hedge", "knowledge-limit hedge: delete")
    tell(NW "in this (guide|article|section|post),? (we|i)('ll| will)" NW, "meta", "writing about the text: give the content")
    tell(NW "((table|section|diagram|list) (below|above) (compares|summarizes)|this section is organized)" NW, "meta", "writing about the text: give the content")
    tell(NW "(could|may|might) (potentially|possibly|arguably)" NW, "stacked-hedge", "stacked hedge: keep one hedge")
    tell(NW "in some cases,? it (may|might|could)" NW, "stacked-hedge", "stacked hedge: keep one hedge")
    tell(NW "(experts|studies|many people|observers|some critics|industry reports|several publications)" WS "(have" WS ")?(say|agree|argue|show|believe|suggest|note|noted|cited)" NW, "vague-authority", "vague authority: name the source or delete")
    tell("," WS "(highlighting|underscoring|emphasizing|ensuring|reflecting|showcasing|fostering|cultivating|contributing to)" NW, "ing-rider", "shallow '-ing' rider: delete or make it a sentence")
    tell(NW "((plays|play|played) a (pivotal|crucial|key|vital) role|marks? a (significant|major) milestone|the future looks bright|reflects a broader|(lasting|enduring) legacy|setting the stage for|indelible mark|exciting times)" NW, "inflation", "inflated significance: say what happened")
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

# pos is where s starts in the paragraph.
function keep(s, n, pos) {
    gsub(SEP, ".", s)
    if (match(s, /^[ \t]+/)) { pos += RLENGTH; s = substr(s, RLENGTH + 1) }
    sub(/[ \t]+$/, "", s)
    if (s != "") { SENT[++n] = s; SPOS[n] = pos }
    return n
}

# Splits a paragraph into SENT[1..n], with the start of each one in SPOS.
# A period after an abbreviation does not end a sentence.
function split_sentences(p,   n, seg, pos, skip) {
    p = " " p
    while (match(p, /[^A-Za-z0-9_](e\.g|i\.e|etc|vs|Dr|Mr|Ms|No)\./)) {
        seg = substr(p, RSTART + 1, RLENGTH - 1)
        gsub(/\./, SEP, seg)
        p = substr(p, 1, RSTART) seg substr(p, RSTART + RLENGTH)
    }
    n = 0
    pos = 0
    while (match(p, /[.!?:][ \t]+[A-Z0-9"'(]/)) {
        seg = substr(p, 1, RSTART)
        skip = RSTART + RLENGTH - 2
        p = substr(p, skip + 1)
        n = keep(seg, n, pos)  # keep() calls match(), so it comes after RSTART is used
        pos += skip
    }
    return keep(p, n, pos)
}

# The line that holds position pos of the paragraph.
function line_of(pos,   k) {
    for (k = plen; k > 1 && LPOS[k] > pos; k--) ;
    return LNO[k]
}

function first_words(s,   n, i, w, out) {
    n = split(s, w, " ")
    if (n <= 5) return s
    out = w[1]
    for (i = 2; i <= 5; i++) out = out " " w[i]
    return out " ..."
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

function flush(   n, i, c, lim, fw, k, lo, hi, even, was_even) {
    if (!plen) return
    n = split_sentences(para)
    npara++
    if (n > 6) add(LNO[1], "paragraph-length", n " sentences in one paragraph (max 6)")
    for (i = 1; i <= n; i++) {
        c = count_words(SENT[i])
        nsent++
        total += c
        if (c > maxw) maxw = c
        lim = imperative(SENT[i]) ? 20 : 25
        if (c > lim + (strict ? 0 : 3))
            add(line_of(SPOS[i]), "sentence-length", c " words (" (lim == 20 ? "instruction" : "description") " max " lim "): " first_words(SENT[i]))

        fw = match(SENT[i], WORD) ? tolower(substr(SENT[i], RSTART, RLENGTH)) : ""
        sub(/'.*/, "", fw)
        FW[i] = fw
        if (i >= 3 && (fw in PRONOUN) && FW[i - 1] == fw && FW[i - 2] == fw && !(i > 3 && FW[i - 3] == fw))
            add(line_of(SPOS[i - 2]), "repeated-opening", "3 sentences in a row start with '" fw "': merge them or start with the action")

        # ponytail: a window of 4 sentences and a band of 2 words. Use the spread of the whole text if this is too blunt.
        LEN[i] = c
        if (i >= 4) {
            lo = hi = c
            for (k = i - 3; k < i; k++) {
                if (LEN[k] < lo) lo = LEN[k]
                if (LEN[k] > hi) hi = LEN[k]
            }
            even = (lo >= 5 && hi - lo <= 2)
            if (even && !was_even) add(line_of(SPOS[i - 3]), "rhythm", "4 sentences in a row of about " lo " words: vary the length")
            was_even = even
        }
    }
    plen = 0
    para = ""
}

# ponytail: counts only words of four letters or more, so "Getting Started with the CLI" passes. Add a list of small words if that matters.
function title_case(s,   n, i, w, cap) {
    n = split(s, w, " ")
    cap = 0
    for (i = 1; i <= n; i++) {
        gsub(/[^A-Za-z]/, "", w[i])
        if (length(w[i]) < 4 || w[i] !~ /[a-z]/) continue
        if (w[i] ~ /^[a-z]/) return 0
        cap++
    }
    return cap >= 4
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

# Finds w in s where the character before it matches the class before and the
# text after it matches the pattern after. Returns the text found, or "".
function find_word(s, w, before, after,   p, off) {
    off = 0
    while ((p = index(substr(s, off + 1), w)) > 0) {
        off += p
        if (substr(s, off - 1, 1) ~ before && match(substr(s, off + length(w)), after))
            return substr(s, off, length(w) + RLENGTH - 1)
    }
    return ""
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

function check_line(no, line, raw,   low, i, m) {
    low = " " tolower(line) " "
    ORIG = " " line " "

    if (index(line, ";")) add(no, "semicolon", "semicolon: write two sentences or a list")
    if (index(line, "—") || index(line, " – ") || index(line, " -- ")) add(no, "dash", "dash as sentence glue: use a period or colon")

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
        if (find_word(low, PHRASAL[i], NW, "^" NW) != "") add(no, "phrasal-verb", "phrasal verb '" PHRASAL[i] "'")

    for (i = 1; i <= ntell; i++)
        if (TRE[i] == "" ? not_only_but(low) : low ~ TRE[i]) add(no, TRULE[i], TMSG[i])

    if (index(raw, "“") || index(raw, "”") || index(raw, "‘") || index(raw, "’"))
        add(no, "curly-quotes", "curly quotes: use straight quotes in Markdown and code")

    for (i = 1; i <= ndecor; i++)
        if (index(line, DECOR[i])) { add(no, "emoji", "emoji as decoration: remove it"); break }
    if (heading) {
        if (index(line, "→") || index(line, "➡")) add(no, "heading-style", "arrow in a heading: remove it")
        if (title_case(line)) add(no, "heading-style", "Title Case heading: use sentence case")
    }

    if (strict) {
        if (low ~ CONTRACTION) add(no, "contraction", "contraction (not permitted in strict mode)")
        if (low ~ NOUN_ONLY) add(no, "noun-only", "'check'/'test' used as a verb (STE: noun only)")
    }
    for (i = 1; i <= nsw; i++)
        if ((m = find_word(low, SWW[i], HY, SWE[i])) != "") add(no, "word", "'" m "' -> " SWA[i])
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
    t = tolower(line)  # link targets are still here
    if (t ~ /utm_source=(chatgpt|openai|copilot|perplexity|claude|gemini)/ || t ~ /oaicite|contentreference|turn[0-9]+(search|view|news|file)[0-9]+/)
        add(NR, "tool-residue", "leftover from a chatbot (link tag or citation mark): remove it")
    if (t ~ /\[(your|insert|company|recipient|client)[ a-z'-]*\]([^(]|$)/)
        add(NR, "tool-residue", "placeholder text: fill it in or remove it")
    line = unlink(line)
    while (match(line, /https?:\/\/[^ \t]+/)) {
        t = substr(line, RSTART, RLENGTH)
        sub(/[.,;:!?)"']+$/, "", t)  # punctuation after a URL belongs to the sentence
        line = substr(line, 1, RSTART - 1) "URL" substr(line, RSTART + length(t))
    }
    labeled = 0
    if (line ~ /^[ \t]*([-*+]|[0-9]+[.)])[ \t]+/) {
        flush()
        sub(/^[ \t]*([-*+]|[0-9]+[.)])[ \t]+/, "", line)
        labeled = (line ~ /^\*\*[^*]+(:\*\*|\*\*:)/)
    }
    sub(/^[ \t]*>[ \t]?/, "", line)
    heading = sub(/^#+[ \t]+/, "", line)
    if (heading) flush()
    gsub(/[*_]/, "", line)
    gsub("’", "'", line)
    gsub("‘", "'", line)

    if (line !~ /[^ \t]/) { flush(); next }

    if (!labeled) nlabel = 0
    else {
        if (++nlabel == 1) label_line = NR
        if (nlabel == 3) add(label_line, "bold-label", "bold label on every list item: remove the bold if the labels add nothing")
    }

    t = line
    sub(/^[ \t]+/, "", t)
    sub(/[ \t]+$/, "", t)
    LNO[++plen] = NR
    LPOS[plen] = (plen == 1) ? 1 : length(para) + 2
    para = (plen == 1) ? t : para " " t
    check_line(NR, line, raw)
    if (heading) flush()
}

END {
    flush()
    printf "%s: %d finding(s) | %d sentences, avg %.1f words, max %d\n", ENVIRON["STE_FILE"], nf, nsent, total / (nsent ? nsent : 1), maxw
    for (i = 1; i <= nf; i++) printf "  %4d  %-16s %s\n", FL[i], FR[i], FM[i]
    exit (nf > 0)
}
