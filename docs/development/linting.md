# Linting

## What we use

We use the following linters:

- rubocop (govuk-rubocop) - ruby linting
- prettier - yaml, markdown and ruby linting
- erblint

## Running linters

To run the linters with autocorrect:

```bash
bin/lint
```

## Overcommit

Overcommit is a gem which adds git pre-commit hooks to your project. Pre-commit hooks run various
lint checks before making a commit. Checks are configured on a project-wide basis in .overcommit.yml.

To install the git hooks locally, run `overcommit --install`. If you don't want the git hooks installed, just don't run this command.

Once the hooks are installed, if you need to you can skip them with the `-n` flag: `git commit -n`
