---
schema: 2
profile: standard@2

processes:
  commit:
    issue: required
    safeguards:
      allowArtifactPaths: []
      maxFileBytes: 5242880
      maxReviewDiffBytes: 307200
    checks:
      - id: project
        command: ["./scripts/check"]
        timeoutSeconds: 900
    reviews: []

  pullRequest:
    issue: required
    checks:
      - id: project
        command: ["./scripts/check"]
        timeoutSeconds: 900
    statuses: []
    reviews:
      - id: regression
        model: openai-codex/gpt-5.4-mini
        actor: repflow-review
        prompt: >-
          Review the complete target/candidate diff for correctness, regressions,
          accidental behavior removal, maintainability, and missing tests or
          documentation. Pay particular attention to database migrations,
          active-workout recovery, workout-history integrity, progression and
          deload calculations, backups, persisted settings, and release safety.
          Cite concrete evidence and do not request unrelated features.
        requiredRecommendation: approve
        timeoutSeconds: 900
    guidance:
      includePolicyBody: true
      files: []

  merge:
    strategy: rebase
    authorization: manual

notifications:
  forgejo: true
---

# Project expectations

Workout of Record is a local-first personal training application whose database may represent years of workout history. Favor straightforward, testable changes and preserve existing user data and behavior unless an issue explicitly requires a change.

Completed workout history is durable personal data. Active-workout persistence must remain recoverable across navigation and process interruption. Progression, deload, mesocycle, movement, and recommendation changes must not silently reinterpret historical workouts.

# Review expectations

Review every pull request for correctness, regression, accidental reversion, maintainability, and appropriate tests. Findings must cite concrete evidence from the candidate and should not expand the issue with unrelated improvements.

Give additional scrutiny to schema migrations, backup and restore behavior, active-workout state, completed workout records, progression calculations, timer behavior, persisted preferences, signing configuration, and interactions across workout planning, execution, and history. Changes touching persisted state should include representative non-personal regression coverage and safe failure behavior where applicable.

# Operational invariants

- Never commit personal databases, backups, API credentials, signing keys, or release keystores.
- Existing databases must migrate forward without silent data loss or reinterpretation.
- Completed workout records must retain their original meaning when movements, templates, preferences, or progression logic later change.
- Backup and restore changes must preserve documented application state and fail safely on malformed, incomplete, or incompatible input.
- Android package identity and signing identity must remain stable across updates.
- Repflow release and deployment operations are unsupported until complete project-owned adapters are added through a separately reviewed policy change. The existing manually authorized release workflow remains governed by `AGENTS.md` and `docs/maintainer/releasing.md`.

# Evidence

`./scripts/check` is the repository-owned aggregate check. It resolves locked Flutter dependencies, runs analysis with all findings fatal, runs the complete Flutter test suite, and runs the release-workflow unit tests.
