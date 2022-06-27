# Laminas GitHub Actions: docs

This action can be used to build and deploy documentation for a Laminas
or Mezzio repository.

The action makes several assumptions:

- You want to use the [laminas/documentation-theme](https://github.com/laminas/documentation-theme).
- You will build and deploy your docs in the gh-pages branch.
- You will build your docs in the `docs/html` directory (though this is configurable).

If no `mkdocs.yml` file is available in the repository, the action aborts early
with no errors.

As an example:

```yaml
- name: Docs
  uses: laminas/documentation-theme/github-actions/docs@master
  with:
    emptyCommits: false
    siteUrl: https://docs.laminas.dev
```

The above will build docs in the `docs/html` subdirectory, will NOT build for
empty commits, and uses an alternate base site URL.

## Behaviors

- By default, the action auto-determines the `siteUrl` based on the repository,
  matching against the repository organization.

- By default, it will build even when the commit is empty.

## Options

- emptyCommits: Specify whether to build documentation for empty commits.
  Defaults to `true`.

- username: Specify a git username under which to make the documentation commit.
  If none is specified, it derives it from the user who made the commit that
  triggered the action.

- useremail Specify a git user email under which to make the documentation commit.
  If none is specified, it uses `${username}@users.noreply.github.com`.

- siteUrl: Specify the scheme and authority of the site URL under which
  documentation will be available. By default, this will be either
  https://docs.laminas.dev or https://docs.mezzio.dev as derived from the
  `${GITHUB_REPOSITORY}` value.

## Environment

This action requires one of either the environment variable `$DEPLOY_TOKEN` or `$DOCS_DEPLOY_KEY`:

- **$DEPLOY_TOKEN** (preferred) should be a GitHub OAuth token with permissions to commit code.
  (In the Laminas and Mezzio organizations, we store this as the `ORGANIZATION_ADMIN_TOKEN` secret at the organization level.)

- **$DOCS_DEPLOY_KEY** (legacy) should be a GitHub deployment key, generated as follows:

  ```bash
  $ ssh-keygen -t rsa -b 4096 -C "${git config user.email}" -f gh-pages -N ""
  # Creates the files:
  # - gh-pages (private SSH key)
  # - gh-pages.pub (public key)
  ```

  Once generated, go to the **Settings** tab of your repository.
  Under **Deploy Keys**, select the **Add Key** button, add the contents of your `gh-pages.pub` file, and select the "Allow Write Access" checkbox.
  Then go to **Secrets**, select the **Add** button, give the new secret the title `DOCS_DEPLOY_KEY`, and paste in the contents of your `gh-pages` file.

## Example workflow

```yaml
name: docs-build

on:
  release:
    types: [published]
  repository_dispatch:
    types: docs-build

jobs:
  build-deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Build and deploy documentation
        uses: laminas/documentation-theme/github-actions/docs@master
        env:
          DEPLOY_TOKEN: ${{ secrets.ORGANIZATION_ADMIN_TOKEN }}
        with:
          emptyCommits: false
```

### Legacy workflows

1. Using a `DOCS_DEPLOY_KEY`

   ```yaml
   name: docs-build

   on:
     release:
       types: [published]
     repository_dispatch:
       types: docs-build

   jobs:
     build-deploy:
       runs-on: ubuntu-latest
       steps:
         - name: Build and deploy documentation
           uses: laminas/documentation-theme/github-actions/docs@master
           env:
             DEPLOY_DEPLOY_KEY: ${{ secrets.DOCS_DEPLOY_KEY }}
           with:
             emptyCommits: false
   ```

2. If your repository has not yet updated to use release branches and/or [automatic-releases](https://github.com/laminas/automatic-releases), and you are still using the "master" branch to reflect current stable, you may also use the following workflow:

   ```yaml
   name: docs-build

   on:
     push:
       branches:
         - master
     repository_dispatch:
       types: docs-build

   jobs:
     build-deploy:
       runs-on: ubuntu-latest
       steps:
         - name: Build and deploy documentation
           uses: laminas/documentation-theme/github-actions/docs@master
           env:
             DOCS_DEPLOY_KEY: ${{ secrets.DOCS_DEPLOY_KEY }}
           with:
             emptyCommits: false
   ```
