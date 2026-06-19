# Commit Message Convention

## Format

```
<scope>(<target>): <subject>

<body>

<footer>
```

- All lines must not exceed 72 characters.
- All commit messages are written in English.

### Subject

- Must not exceed 50 characters.
- Use imperative mood (e.g., `add`, not `added` / `adding`).
- Do not end with a period.
- Start with a lowercase letter unless the first word is a proper noun.

### Scope and Target

The scope identifies the dimension of the repository affected by the change.

| Scope | Meaning | Target example |
|-------|---------|----------------|
| `memory` | `FytcAgentMemory` core package | `short-term`, `entity`, `long-term`, `unified`, `utils` |
| `test` | Test suites | `runtests`, `short-term`, `entity` |
| `docs` | Documentation | `readme`, `api` |
| `meta` | Framework and infrastructure changes | `ci`, `contributing`, `project`, `compat` |
| `repo` | Repository management | `gitignore`, `license` |

- `target` is the slug of the affected entry, without path prefix or trailing `/`.
- For `memory` scope, `target` is the source file or module touched.
- For `meta` scope, `target description` describes the changed object rather than a module name.

### Body

- Separate from subject with one blank line.
- Use imperative mood.
- Explain **why** the change was made, not **what** was changed (the subject already covers what).
- Each line must not exceed 72 characters.
- Use unordered lists (`-`) to enumerate specific changes.

### Footer

- AI-assisted commits **must** include an `Assisted-by` trailer (see AI Attribution section).
- Purely human commits require no footer trailer.
- The `Co-authored-by` trailer is **prohibited** for AI attribution; use `Assisted-by` exclusively.

## Subject Verbs

| Scenario | Recommended verbs | Example |
|----------|-------------------|---------|
| New module or feature | `add`, `implement`, `introduce` | `memory(short-term): add ShortTermMemory rolling window` |
| Remove code or file | `remove`, `delete` | `memory(entity): remove legacy search helper` |
| Update content | `update`, `revise`, `refine` | `memory(entity): refine substring matching logic` |
| Bug fix | `fix`, `correct` | `memory(short-term): fix capacity check boundary` |
| Tests | `add`, `cover`, `harden` | `test(entity): cover exact key hit path` |
| Refactor or rename | `rename`, `restructure`, `reorganize` | `memory(utils): restructure helper functions` |
| Dependencies / compat | `bump`, `pin`, `relax` | `meta(compat): bump julia compat to 1.11` |
| Framework or infrastructure | `add`, `update`, `introduce`, `harden` | `meta(ci): introduce GitHub Actions test matrix` |

## AI Attribution

Based on the [Linux Kernel AI Coding Assistants](https://docs.kernel.org/process/coding-assistants.html) guidelines.

### Format

```
Assisted-by: AGENT_NAME:MODEL_NAME
```

### Rules

- AI tools **must not** add `Signed-off-by` tags; only humans can legally certify the Developer Certificate of Origin.
- The human committer is responsible for reviewing all AI-generated content and taking full responsibility for the contribution.
- When multiple AI tools assisted, use one `Assisted-by` line per tool.
- The `Co-authored-by` trailer is **prohibited** for AI attribution.

### Canonical Agent Names

`AGENT_NAME` must exactly match one of the following entries:

| AGENT_NAME | Description |
|------------|-------------|
| `Codex` | OpenAI Codex |
| `ClaudeCode` | Anthropic Claude |
| `QwenCode` | Alibaba Qwen Code |
| `GitHub-Copilot` | GitHub Copilot |
| `OpenCode` | OpenCode CLI |

### Canonical Model Names

`MODEL_NAME` should be lowercase and may include version numbers or descriptors to specify the exact model used, e.g., `gemini-3.5-flash`, `claude-3-5-sonnet`, `gpt-4o`.
