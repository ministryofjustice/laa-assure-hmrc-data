# CI/CD - Deployment


We use github actions (GHA) for our CI and CD. This was decided upon because:

- They can do most anything CircleCI and other CI/CD tools provide, and often more simply.
- The documentation is of a good quality.
- There are many resuable actions available, but note that [care should be taken when using them](https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions#using-third-party-actions)
- writing your own github action is relatively simple, compared to orbs for example.
- cloud-platform automatically generates `KUBE_` secrets for use in deployment steps
- You can have multiple github action workflows in separate flows, rather than one large one.

