# STE80

[![CI](https://github.com/adrianhaj/ste80/actions/workflows/ci.yml/badge.svg)](https://github.com/adrianhaj/ste80/actions/workflows/ci.yml) [![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

A Claude Code plugin with one skill, `ste80`. The skill makes AI-written text read like a careful person wrote it. It does not change what the text says. It works in two passes:

1. **Remove the AI tells.** The 26 tells from Wikipedia's [Signs of AI writing](https://en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing), in the catalog of [blader/humanizer](https://github.com/blader/humanizer).
2. **Rebuild the sentences in STE80.** That is "80% of the way to ASD-STE100", the method that Andrej Karpathy shared. ASD-STE100 is the controlled English of aircraft maintenance manuals.

The skill text comes from [Dodaios/ste80-humanizer](https://github.com/Dodaios/ste80-humanizer), with small changes. This version needs no Python. Its checker is a POSIX `sh` and `awk` script.

**Before:**
> Great question! Kubernetes liveness probes are a powerful mechanism that enables the kubelet to determine whether a container is healthy — and it's not just a health check, it's your first line of defense. When a probe fails, the container will be automatically restarted by the kubelet, ensuring that your application remains available. However, it's important to note that misconfigured probes could potentially cause cascading restarts, so parameters like `initialDelaySeconds` and `failureThreshold` should be carefully tuned.
>
> Get this right, and your cluster heals itself.

**After:**
> A liveness probe tells the kubelet if a container is healthy. If the probe fails, the kubelet restarts the container. This keeps the application available.
>
> But a misconfigured probe can cause cascading restarts. To prevent this, tune parameters like `initialDelaySeconds` and `failureThreshold` with care.

The goal is text that people read easily. The skill does not try to get past AI detectors.

## Install

```bash
claude plugin marketplace add adrianhaj/ste80
claude plugin install ste80@ste80
```

To update to a newer release, refresh the marketplace, update the plugin and restart Claude Code:

```bash
claude plugin marketplace update ste80
claude plugin update ste80@ste80
```

For another agent, copy the folder `skills/ste80` into the skills folder of that agent. The folder is a plain agent skill: one `SKILL.md`, its references and the checker.

## Use

```
/ste80:ste80
<paste text>
```

Or ask in your own words:

```
This sounds like ChatGPT wrote it. Make it sound like a person.
Rewrite this README 80% of the way to ASD-STE100.
Explain how TLS handshakes work in STE.
Light touch: just remove the AI stuff from docs/intro.md.
Convert docs/runbook.md to strict STE.
Does this email sound like AI? Just tell me, don't rewrite it.
```

| Mode | When | What it does |
|---|---|---|
| **Humanize (default)** | Normal requests | Pass 1 fully, Pass 2 at 80%. Keeps your voice. |
| **Light** | "light touch", "just remove the AI stuff" | Pass 1, plus only the worst sentences from Pass 2. |
| **Strict STE** | "strict", "full STE", procedures, safety notes | Pass 1 and all of Pass 2 at 100%. |

The skill keeps every fact. It keeps "may" as "may" and "40+" as "40+". It adds nothing, and it flags contradictions in the source. If you add a sample of your own writing, the skill matches its sentence length, words and punctuation.

## The method

[Andrej Karpathy suggested](https://x.com/karpathy/status/2105819303471976479) that you ask an LLM to write "80% of the way to ASD-STE100", because the full specification is too strict for normal prose.

ASD-STE100 (Simplified Technical English) is from the aerospace industry of the 1980s. Its writers made it for mechanics whose first language is not English. Its rules:

- 20 words per instruction and 25 per description
- one instruction per sentence
- active voice and simple tenses
- one meaning per word, with about 900 approved words
- one topic per paragraph, and six sentences at most

At 80%, the skill keeps all of the structure and only as much of the vocabulary as still sounds natural:

| STE rule | 100% (Strict mode) | 80% (default) |
|---|---|---|
| Sentence length 20 / 25 | Hard limit | A few words over is fine |
| One idea per sentence | Always | Always |
| Active voice, simple tenses | Always | Always |
| Approved dictionary only | Yes | No, use the plain common word |
| "check", "test" as verbs | No | Yes |
| "may", "should" | No | Yes, for real uncertainty |
| Contractions | No | Yes, in casual text |
| Semicolons | No | No |

STE fixes sentence structure. It does not remove chatbot phrases, so Pass 1 does that first.

## Layout

| Path | What |
|---|---|
| `skills/ste80/SKILL.md` | The skill: modes, the 26 AI tells (§1 to §26), the 15 STE80 rules (S1 to S15), fidelity rules |
| `skills/ste80/references/ai-tells.md` | Each tell in full: Watch for, Problem, Before, After |
| `skills/ste80/references/ste80-rules.md` | Examples for each STE80 rule |
| `skills/ste80/references/strict-mode.md` | The strict rule set and a checklist |
| `skills/ste80/references/word-swaps.md` | More than 100 plain-word swaps |
| `skills/ste80/references/worked-example.md` | One text after Pass 1 and after Pass 2 |
| `skills/ste80/scripts/ste_check.sh`, `ste_check.awk` | The checker |
| `evals/` | Four cases in the `claude plugin eval` format |
| `tests/` | Tests for the checker |

The skill reports its edits by number, for example "§1, §8, S2", so you can look each one up.

## Checker

`skills/ste80/scripts/ste_check.sh` is a small linter. It needs only `sh` and `awk`, which every Unix system has. On Windows, use Git Bash or WSL.

```bash
sh skills/ste80/scripts/ste_check.sh README.md
sh skills/ste80/scripts/ste_check.sh --strict docs/runbook.md
cat draft.txt | sh skills/ste80/scripts/ste_check.sh -
```

| Pass | What the checker flags |
|---|---|
| 1 | not-X-but-Y, chatbot phrases, run-ups, fake depth, stacked hedges, vague authority and association, "-ing" riders, inflated claims, AI words, hyphen pairs, curly quotes |
| 2 | sentence and paragraph length, semicolons, dashes, passive voice, perfect and progressive tenses, "-ing" forms, phrasal verbs |

The exit code is 0 for no findings, 1 for findings and 2 for a usage error. The checker is a heuristic. It is not an AI detector and it is not a compliance checker.

## Develop

```bash
sh tests/test_ste_check.sh
shellcheck skills/ste80/scripts/ste_check.sh tests/test_ste_check.sh
claude plugin validate .
```

CI runs the tests with gawk, mawk, busybox awk and the BWK awk that macOS uses. It also runs them in Git Bash on Windows. To test one awk yourself, set `STE_AWK`, for example `STE_AWK=mawk sh tests/test_ste_check.sh`.

`tests/expected/` holds the output that the checker must give for `tests/fixtures/sample.md`. If you change a rule on purpose, read the new output, then write it to those files.

To run the eval cases:

```bash
claude plugin eval . --allow-tools Write,Edit,Bash
```

Rules for a change to the skill:

- Write in the style that the skill teaches.
- Keep `SKILL.md` below 500 lines. Long examples go in `references/`.
- Keep the checker in sync with the tells and words in `SKILL.md`, where a pattern can find them.
- Do not copy the ASD-STE100 specification or its dictionary. ASD owns the copyright. Write the rules in your own words.
- Do not claim compliance. The skill and the checker give "STE style", not certified STE.

### Release

1. Bump `version` in `.claude-plugin/plugin.json` as the last commit of the change (`chore: release X.Y.Z`). Users get the new version once that commit is on `main`.
2. After the merge, `.github/workflows/release.yml` creates the tag `ste80--vX.Y.Z` on that commit. It also publishes a GitHub release that lists the pull requests since the previous release. It does nothing when that version already has a release.
3. Optional: edit the release on GitHub to add a few lines about what changed above that list.

Only the code owner in `.github/CODEOWNERS` can merge to `main`, so only the code owner can start a release.

## Limits

- **STE is for clear explanatory text.** For fiction, speeches and brand copy, the skill does Pass 1 only.
- **STE is an English standard.** For other languages, the skill applies the tells and the structure rules, but not the English word lists.
- **"STE style" is not "STE compliant".** Compliance needs the official dictionary, trained writers and review.

## Credits

- [Dodaios/ste80-humanizer](https://github.com/Dodaios/ste80-humanizer) (MIT). The skill text, the references, the eval cases and the rules of the checker come from it.
- [blader/humanizer](https://github.com/blader/humanizer) by Siqi Chen (MIT). Pass 1 follows its catalog of 26 patterns.
- Wikipedia, [Signs of AI writing](https://en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing) (WikiProject AI Cleanup).
- Andrej Karpathy, for the ["80% of the way to ASD-STE100"](https://x.com/karpathy/status/2105819303471976479) method.
- ASD-STE100 Issue 9 (2025): https://www.asd-ste100.org

Both license notices are in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

## Disclaimer

This skill does not contain the ASD-STE100 specification or its dictionary. The STE rules are paraphrased and simplified. ASD-STE100 and Simplified Technical English are trademarks of ASD (AeroSpace, Security and Defence Industries Association of Europe). This project is not affiliated with or endorsed by ASD.

## License

[MIT](LICENSE)
