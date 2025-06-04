# GitHub Copilot Instructions

This document guides GitHub Copilot to generate code and suggestions consistent with the Healthcare Agent Orchestrator repository.

## Project Overview
- A Python Azure Functions–based orchestrator service.
- Dockerized for local development and production.
- Deployed and managed via Azure CLI and Azure DevOps pipelines.

## General Coding Style
- Follow existing code style—use `flake8`/`black` for Python.
- Prefer `async`/`await` over callbacks where applicable.
- Use descriptive names; add docstrings for public methods.
- Keep functions small, single-responsibility, and side-effect free where possible.
- Handle errors explicitly and return informative messages.

## Python / Azure Functions
- Use `python3` and `pip3`; dependencies tracked in `requirements.txt`.
- Azure Functions in `./functions` folder; each function in its own subdirectory.
- Follow PEP8; use type hints where helpful.
- For Azure Functions, when generating code, invoke the `azure_development-get_azure_function_code_gen_best_practices` tool.

## Docker
- Base images pinned to specific versions in `Dockerfile` and `docker-compose.yml`.
- Keep layers minimal; cache dependencies before copying source.
- Expose ports and set necessary environment variables via `.env`.

## Azure CLI & Deployment
- Use `az` commands for resource CRUD; group related resources in the same RG.
- Infrastructure defined in Bicep templates; prefer Bicep over ARM JSON.
- Follow Bicep best practices: use parameters, variables, and outputs appropriately.
- Modularize Bicep templates; use modules for reusable components.
- When generating or modifying Bicep templates or CLI commands, invoke `azure_development-get_deployment_best_practices`.
- Secure secrets in Key Vault; avoid inline credentials.
- Use consistent naming conventions across all Azure resources.

## Git Workflow
- Branch naming: `feature/*`, `bugfix/*`, `hotfix/*`.
- Commits should follow Conventional Commits (type(scope): description).
- Open PRs against `main`; link related work items or issues.

## Testing & CI/CD
- Include unit tests for new features and bug fixes using `pytest`.
- Add integration tests where components interact (HTTP, Azure services, Docker).
- Ensure CI runs lint, tests, and security scans.

## Copilot Best Practices
- When offering code snippets, reference existing modules and imports.
- Suggest minimal diffs—focus on the change at hand.
- If the user is working on Azure Functions or SWA, call the relevant `azure_development-*` tool for guidance.
- Avoid boilerplate unrelated to the current context.

