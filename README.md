# SwiftGuard

AI-powered PR review agent for Swift/SwiftUI projects. Runs as a GitHub Action on every pull request.

## What it does

SwiftGuard acts as an automated senior engineer, analyzing your PRs across 7 phases:

| Phase | What | LLM needed? |
|-------|------|-------------|
| 1. Context Gathering | Git diff, dependencies, existing tests, commits | No |
| 2. Static Analysis | PR size, commit lint, naming, docs, UI elements | No |
| 3. LLM Analysis | Architecture, security, performance, breaking changes | Yes |
| 4. Test Generation | XCUITests with compiler feedback loop | Yes |
| 5. Test Execution | Run tests on simulator, capture screenshots | No |
| 6. Visual Analysis | Vision LLM reviews screenshots | Yes |
| 7. Report | PR comment, reviewer assignment, labels | No |

## Quick start

### Use in your repo (GitHub Action)

1. Add `ANTHROPIC_API_KEY` (or `OPENROUTER_API_KEY`) to your repo secrets

2. Create `.github/workflows/swiftguard.yml`:

```yaml
name: SwiftGuard
on:
  pull_request:
    types: [opened, synchronize, reopened]

permissions:
  pull-requests: write
  contents: read

jobs:
  review:
    runs-on: macos-15
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - uses: issyugk3/Hackathon-XCUItestAgent@main
        with:
          anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
```

3. Open a PR — SwiftGuard posts a review comment automatically.

### Run locally

```bash
# Build
swift build

# Dry run (no API key needed)
.build/debug/swiftguard /path/to/project --mode local --base-sha HEAD~1 --dry-run

# Full run with LLM
export OPENROUTER_API_KEY="sk-or-..."
.build/debug/swiftguard /path/to/project --mode local --base-sha HEAD~1
```

## Configuration

Add `.swiftguard.yml` to your project root:

```yaml
llm:
  text:
    provider: openrouter        # anthropic | openai | openrouter | openai-compatible
    model: openai/gpt-4o
  vision:
    provider: openrouter
    model: openai/gpt-4o

testing:
  scheme: MyApp
  simulator: "iPhone 16 Pro"
  enable_execution: false       # set true to run XCUITests

code_quality:
  commit_format: conventional
  architecture: mvvm
  naming:
    enforce_swift_guidelines: true
  max_pr_size:
    small: 100
    medium: 300
    large: 500

team:
  auto_assign_reviewers: true
  module_owners:
    - path: "Sources/Auth/"
      owners: ["@alice"]
  require_doc_update: true
  auto_labels: true
```

## What SwiftGuard catches

- **Security**: hardcoded secrets, force unwraps, insecure network calls
- **Performance**: retain cycles, unnecessary re-renders, main thread blocking
- **Code quality**: naming violations, commit message format, missing docs
- **Architecture**: pattern violations, breaking changes, impact analysis
- **Visual**: layout issues, accessibility, consistency (via screenshots)
- **Team**: auto-assign reviewers, PR size labels, split suggestions

## Supported LLM providers

| Provider | Text | Vision | Env var |
|----------|------|--------|---------|
| Anthropic | Yes | Yes | `ANTHROPIC_API_KEY` |
| OpenAI | Yes | Yes | `OPENAI_API_KEY` |
| OpenRouter | Yes | Yes | `OPENROUTER_API_KEY` |
| OpenAI-compatible | Yes | No | `LLM_API_KEY` |

## CLI options

```
swiftguard [project-path] [options]

Options:
  --mode <mode>           github-action or local (default: local)
  --base-sha <sha>        Base commit for diff
  --pr-number <number>    PR number (github-action mode)
  --repo <owner/repo>     Repository (github-action mode)
  --simulator <id>        Simulator device ID
  --config <path>         Path to .swiftguard.yml
  --dry-run               Skip LLM phases, static analysis only
```

## License

MIT
