# Contributing

## Branching
- main: production releases
- develop: staging/integration
- feature/<name>: new work (branch from develop)
- hotfix/<name>: urgent fixes (branch from main)

## Commit Message Convention (light Conventional Commits)

Use one of these prefixes:

- feat: a new feature
- fix: a bug fix
- chore: tooling, config, dependencies, small maintenance
- docs: documentation only changes
- refactor: code change that neither fixes a bug nor adds a feature

### Examples
- feat: add shows list endpoint
- fix: prevent overbooking when pending reservations expire
- chore: add docker-compose for postgres
- docs: add environment setup guide
- refactor: simplify reservation status transitions

## Pull Requests
- Keep PRs small and focused
- Describe what changed and how to test
- Link the Trello card if possible
