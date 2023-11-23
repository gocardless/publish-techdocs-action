# Generate and Publish TechDocs to GCS

**EXPERIMENTAL: Use at own risk**

> [GitHub Action](https://github.com/features/actions) for [Publishing TechDocs](https://backstage.io/docs/features/techdocs/techdocs-overview)

[![GitHub Release][release-img]][release]
[![GitHub Marketplace][marketplace-img]][marketplace]
[![License][license-img]][license]

## Table of Contents

- [Usage](#usage)
  - [Workflow](#workflow)

## Usage

### Workflow

```yaml
name: publish-techdocs
on:
  push:
    branches:
      - master
    paths:
      - docs/**
jobs:
  publish-techdocs:
    name: Publish Techdocs
    runs-on: ubuntu-latest
    strategy:
      matrix:
        n:
          - env: staging
            secret: TECHDOCS_GCS_SECRET_ACCESS_KEY_STAGING
          - env: production
            secret: TECHDOCS_GCS_SECRET_ACCESS_KEY_PRODUCTION
    steps:
      - uses: actions/checkout@v3
      - name: Publish TechDocs - ${{ matrix.n.env }}
        uses: gocardless/publish-techdocs-action@master
        with:
          publisher: googleGcs
          credentials: ${{ secrets[matrix.n.secret] }}
          bucket: gc-prd-tech-docs-${{ matrix.n.env }}
          entity: default/component/<YOUR_SERVICE_NAME_GOES_HERE>
```


[release]: https://github.com/gocardless/publish-techdocs-action/releases/latest
[release-img]: https://img.shields.io/github/release/gocardless/publish-techdocs-action?include_prereleases&color=blue
[marketplace]: https://github.com/marketplace/actions/publish-techdocs
[marketplace-img]: https://img.shields.io/badge/marketplace-publish--techdocs-blue?logo=github
[license]: https://github.com/gocardless/publish-techdocs-action/blob/master/LICENSE
[license-img]: https://img.shields.io/github/license/gocardless/publish-techdocs-action
