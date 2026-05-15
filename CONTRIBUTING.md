# Contributing to Tennis Point Logger

Thank you for your interest in contributing! This document provides guidelines for both humans and AI agents to ensure high-quality contributions and a smooth release process.

## 🚀 Development Workflow

### 1. Worktrees (Required for AI Agents)
Always work in a git worktree to maintain an isolated environment.
```powershell
# Create a worktree for your task
git worktree add ../tennis-point-logger-<task-name> -b <feature-branch-name>
```

### 2. Branching Strategy
- **Default Branch**: `main`
- **Feature Branches**: Create a branch for every change (e.g., `feat/new-scoring`, `fix/issue-123`).
- **Direct Pushes**: Never push directly to `main` unless you are performing a version bump or dependency update that has been verified locally.

### 3. Commit Messages
We follow a simplified version of [Conventional Commits](https://www.conventionalcommits.org/):
- `feat:` for new features
- `fix:` for bug fixes
- `docs:` for documentation changes
- `chore:` for maintenance tasks (version bumps, dependency updates)
- `refactor:` for code changes that neither fix a bug nor add a feature

Example: `feat: add support for 10-point match tiebreaks`

## 🧪 Quality Guardrails

Before submitting a Pull Request or pushing a tag, **always** run the following locally:

1. **Static Analysis**: Ensure there are no lint or type errors.
   ```powershell
   flutter analyze
   ```
2. **Unit Tests**: Ensure no regressions in the scoring engine or models.
   ```powershell
   flutter test
   ```

## 📦 Release Process

The release process is automated via GitHub Actions and triggered by **version tags** (e.g., `v2.0.3`).

### ⚠️ The Golden Rule of Releases
**The version in `pubspec.yaml` MUST match the git tag.**

If you push a tag `vX.Y.Z`, the `version` field in `pubspec.yaml` must be `X.Y.Z+N`. If they do not match, the CI/CD build **will fail**.

#### How to Release Correctly:
1. Update the version in `pubspec.yaml`:
   ```yaml
   version: 2.0.3+14  # Ensure the semver matches your intended tag
   ```
2. Commit and push this change to `main`.
3. Create and push the tag:
   ```powershell
   git tag v2.0.3
   git push origin v2.0.3
   ```

## 🤖 AI Agent Guidelines

If you are an AI agent working on this repo:
- **Read `CLAUDE.md`**: It contains specific instructions for your environment (PowerShell, worktrees, etc.).
- **Verify before Tagging**: Always run `flutter analyze` and `flutter test` before suggesting or performing a release.
- **Check `pubspec.yaml`**: Before pushing a tag, double-check that the file content matches the tag name.
- **AAB for Google Play**: Note that the release workflow now generates both `.apk` and `.aab` files. Ensure you don't break the App Bundle build.

## 🛠️ Environment Setup
See the [README.md](README.md) for detailed instructions on setting up Flutter, Android signing, and Google Sheets integration.
