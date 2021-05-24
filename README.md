# Generate and Publish TechDocs to GCS

> [GitHub Action](https://github.com/features/actions) for [Publishing TechDocs](https://backstage.io/docs/features/techdocs/techdocs-overview)

[![GitHub Release][release-img]][release]
[![GitHub Marketplace][marketplace-img]][marketplace]

## Table of Contents

- [Usage](#usage)
  - [Workflow](#workflow)

## Usage

### Workflow

```yaml
name: build
on:
  push:
    branches:
      - main
  pull_request:
jobs:
  build:
    name: Build
    runs-on: ubuntu-18.04
    steps:
      - name: Publish TechDocs
        uses: gocardless/publish-techdocs-action@master
        with:
          publisher: googleGcs
          credentials: ${{ secrets.GOOGLE_APPLICATION_CREDENTIALS }}
          bucket: bucket_name
          entity: default/Component/Backstage
```


[release]: https://github.com/gocardless/publish-techdocs-action/releases/latest
[release-img]: https://img.shields.io/github/release/gocardless/publish-techdocs-action.svg?logo=github
[marketplace]: https://github.com/marketplace/actions/publish-techdocs-action
[marketplace-img]: https://img.shields.io/badge/marketplace-publish-techdocs-action-blue?logo=github