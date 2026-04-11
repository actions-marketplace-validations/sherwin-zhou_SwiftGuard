# SwiftGuard — AI-Powered PR Review Agent for Swift Projects

A Swift CLI tool that runs in GitHub Actions to act as an automated senior engineer on every pull request, providing comprehensive code review, test generation, and visual analysis.

---

## Target User

Swift/SwiftUI teams who want automated, comprehensive PR reviews — covering code quality, security, performance, testing, and visual regression — without manual reviewer burden.

---

## 3 Core Capabilities

### 1. Static + LLM Code Analysis
- **Static checks** (no LLM): PR size, commit message lint, naming conventions, doc coverage, UI element extraction
- **LLM-powered analysis**: architecture compliance, security vulnerabilities, performance hotspots, breaking changes detection, impact/blast radius assessment, PR split suggestions
- Single combined LLM call with structured JSON output to minimize cost

### 2. Visual-First Test Generation & Execution
- Generates XCUITests (regression + incremental) targeting PR changes
- Compiler feedback loop: feeds Swift compiler errors back to LLM, retries up to 3x
- Runs tests on simulator, captures screenshots at every step
- Vision LLM reviews screenshots for layout issues, accessibility, consistency, dark mode

### 3. Comprehensive PR Reporting & Team Workflow
- Posts a single structured PR comment with all findings organized by severity
- Auto-assigns reviewers based on CODEOWNERS / module ownership config
- Applies labels (size S/M/L/XL, needs-split, needs-docs, security-review)
- Uploads screenshot artifacts for visual evidence

---

## Architecture

### Pipeline: 7 Phases

```
PR push → Phase 1: Context Gathering (git diff, deps, existing tests, config, commits, owners)
        → Phase 2: Static Analysis (PR size, commit lint, naming, docs, UI elements)
        → Phase 3: LLM Analysis (architecture, security, performance, breaking changes, impact)
        → Phase 4: Test Generation (regression + incremental, compiler feedback loop)
        → Phase 5: Test Execution (xcodebuild on simulator, screenshot capture)
        → Phase 6: Visual Analysis (vision LLM reviews screenshots)
        → Phase 7: Report + Team Actions (PR comment, reviewer assignment, labels)
```

### Key Data Models

| Model | Purpose |
|-------|---------|
| `SwiftGuardConfig` | Root config from `.swiftguard.yml` |
| `ProjectContext` | Phase 1 output — everything known about this PR |
| `StaticAnalysisResult` | Phase 2 output — pure Swift/regex findings |
| `LLMAnalysisResult` | Phase 3 output — architecture, security, perf, breaking changes |
| `GeneratedTests` | Phase 4 output — regression + incremental test code |
| `TestExecutionResult` | Phase 5 output — pass/fail, screenshots |
| `VisualAnalysis` | Phase 6 output — vision LLM findings |
| `SwiftGuardReport` | Phase 7 output — assembled PR comment |

### Multi-LLM Provider System

Protocol-based (`LLMProvider`) with implementations for:
- Anthropic (native API)
- OpenAI (chat completions)
- OpenRouter (OpenAI-compatible + headers)
- OpenAI-Compatible (custom baseURL)

Separate text and vision providers configurable in `.swiftguard.yml`.

---

## Project Structure

```
swiftguard/
├── Package.swift
├── Sources/swiftguard/
│   ├── main.swift
│   ├── Config/          — SwiftGuardConfig, ConfigLoader, CLIArguments
│   ├── LLM/             — LLMProvider protocol + 4 implementations
│   ├── Phase1_Context/  — DiffAnalyzer, DependencyResolver, TestScanner, etc.
│   ├── Phase2_Static/   — PRSizeChecker, CommitLinter, NamingChecker, etc.
│   ├── Phase3_LLMAnalysis/ — CodeAnalyzer, prompts, response parser
│   ├── Phase4_TestGen/  — TestGenerator, CompilerFeedbackLoop
│   ├── Phase5_Execute/  — TestRunner, ResultParser, ScreenshotExtractor
│   ├── Phase6_Vision/   — VisionAnalyzer, ImageProcessor
│   ├── Phase7_Report/   — ReportAssembler, GitHubClient, MarkdownFormatter
│   └── Models/          — All data models
```

---

## Technology Stack

| Component | Technology |
|-----------|-----------|
| Language | Swift 5.9+ |
| CLI framework | swift-argument-parser |
| Config parsing | Yams (YAML) |
| Build system | Swift Package Manager |
| Test execution | xcodebuild (simulator) |
| CI/CD | GitHub Actions (macos-15 runner) |
| LLM APIs | Anthropic, OpenAI, OpenRouter |
| GitHub integration | GitHub REST API (PR comments, labels, reviewers) |

---

## CLI Interface

```bash
# GitHub Action mode
swiftguard . \
  --mode github-action \
  --base-sha <sha> \
  --pr-number <number> \
  --repo <owner/repo> \
  --simulator <sim-id>

# Local interactive mode
swiftguard . --mode local
```

---

## Configuration

`.swiftguard.yml` in project root — controls LLM providers, testing settings, code quality rules, security scan, team workflow, and report format. See DESIGN-v4.md section 8 for full schema.

---

## Build Plan

| Day | Focus |
|-----|-------|
| 1 | Foundation: Package.swift, models, config, LLM providers |
| 2 | Phase 1 (context) + Phase 2 (static analysis) |
| 3 | Phase 3 (LLM analysis + prompts) |
| 4 | Phase 4 (test gen) + Phase 5 (test execution) |
| 5 | Phase 6 (vision) + Phase 7 (report + GitHub) |
| 6 | Integration, GitHub Action workflow, error handling |
| 7 | Polish, SampleApp, README, multi-provider testing |
