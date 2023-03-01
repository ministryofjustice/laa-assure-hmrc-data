# CI/CD - Deployment


We use github actions (GHA) for our CI and CD. This was decided upon because:

- They can do most anything CircleCI and other CI/CD tools provide, and often more simply.
- The documentation is of a good quality.
- There are many resuable actions available, but note that [care should be taken when using them](https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions#using-third-party-actions)
- writing your own github action is relatively simple, compared to orbs for example.
- cloud-platform automatically generates `KUBE_` secrets for use in deployment steps
- You can have multiple github action workflows in separate flows, rather than one large one.



# Helm

## What was done

### create the helm chart/package for the app
```sh
cd laa-assure-hmrc-data
mkdir .helm
cd .helm
helm create assure-hmrc-data
```

### amend files
 - amend the ingress.yaml
 - amend the deployment.yaml and rename to deployment-web.yaml
 - remove serviceaccount.yaml and all references to it
 - remove test director
 - remove various unused config in values and template files
 - add `_envs.tpl` with secret references


## Helm chart development cheat sheet

### Lint to ensure everything is in order

To identify linting errors you can run:

```sh
# for staging
helm lint .helm/assure-hmrc-data --values .helm/assure-hmrc-data/values/staging.yaml
```

### Dry run to check rendered yaml

To view the resulting yaml files that will be gnenerated by the helm templating engine but without actually installing/upgrading you can run:

```sh
# using staging
helm upgrade my-dry-run-version .helm/assure-hmrc-data \
  --debug \
  --dry-run \
  --install \
  --wait \
  --namespace laa-assure-hmrc-data-staging \
  --set image.repository="<ECR_TEAM_REPO_URL>" \
  --set image.tag="<ECR_TEAM_REPO_NAME:latest>" \
  --values .helm/assure-hmrc-data/values/staging.yaml

```

### Upgrade (or install) of chart (in cluster)
i.e. To manually deploy a branch/commit to staging

```sh
helm upgrade assure-hmrc-data .helm/assure-hmrc-data \
  --install --wait \
  --namespace laa-assure-hmrc-data-staging \
  --set image.repository="<ECR_TEAM_REPO_URL>" \
  --set image.tag="latest" \
  --values .helm/assure-hmrc-data/values/staging.yaml
```

### Local docker build, push and deploy

Secrets mentioned as ENVVARS below can be retrieved from kubernetes ECR secret in UAT namespace.

- Login into Docker with ECR credentials
```sh

AWS_ACCESS_KEY_ID=ecr-access-key \
AWS_SECRET_ACCESS_KEY=ecr-secret-access-key \
  aws ecr get-login-password --region ${ECR_REGION} | docker login --username AWS --password-stdin ${ECR_URL}
```

- Build the image
```sh
docker build \
  --label build.git.sha="my-local-commit-sha" \
  --label build.git.branch="my-local-branch" \
  --label build.date=$(date +%Y-%m-%dT%H:%M:%S%z) \
  --build-arg APP_BUILD_DATE=$(date +%Y-%m-%dT%H:%M:%S%z) \
  --build-arg APP_BUILD_TAG="my-local-branch" \
  --build-arg APP_GIT_COMMIT="my-local-commit-sha" \
  --pull \
  --tag app .

# tag that image locally
docker tag app <ECR_TEAM_REPO_NAME:latest>
docker push "<ECR_URL>:my-local-commit-sha"
```

- Deploy to staging

```sh
helm upgrade assure-hmrc-data .helm/assure-hmrc-data \
  --install --wait \
  --namespace laa-assure-hmrc-data-staging \
  --set image.repository="<ECR_TEAM_REPO_URL>" \
  --set image.tag="my-local-commit-sha" \
  --values .helm/assure-hmrc-data/values/staging.yaml
```
