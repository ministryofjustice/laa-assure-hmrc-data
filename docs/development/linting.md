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

### Pre-commit hooks using DevSecOps

We use the Ministry of Justice pre-commit hooks for scanning hardcoded secrets and credentials. More information can be found [here] (https://github.com/ministryofjustice/devsecops-hooks).

To set-up locally:

Install prek
```shell
brew install prek
```

Install the pre-commit hook
```shell
prek install
```

Launch Docker Desktop locally

Now, when you commit, .pre-commit-config.yaml containing the pre-commit hook should run.
