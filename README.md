# Codex Desktop Linux Builder

This repository is a release builder for
[`ilysenko/codex-desktop-linux`](https://github.com/ilysenko/codex-desktop-linux).
It does not mirror or merge the upstream Git history.

The scheduled workflow runs once per day and:

1. resolves the exact upstream `main` commit;
2. downloads and fingerprints the current ChatGPT DMG;
3. skips the expensive build when that source/DMG pair already has a managed
   release;
4. checks out upstream into an isolated directory;
5. builds x86-64 DEB, RPM, and AppImage packages without the local update
   manager;
6. inspects the package payloads and publishes all three files as one GitHub
   Release.

Release versions use the upstream application version followed by a Beijing
time build suffix, for example:

```text
v26.715.21245+build2607171958
```

## Configuration

No personal access token or fork synchronization secret is required. Enable
GitHub Actions and allow workflows to create releases by selecting:

```text
Settings -> Actions -> General -> Workflow permissions -> Read and write permissions
```

The workflow otherwise uses only the repository-scoped `GITHUB_TOKEN`.

Run it manually from **Actions -> Build upstream release -> Run workflow**.
The manual form includes a `force_build` option for rebuilding an already seen
upstream source/DMG pair.

## Downstream packaging policy

Upstream is never modified in this repository. During a workflow run,
`scripts/prepare-upstream.sh` applies a small build-only overlay to the temporary
checkout:

- native packages are built with `PACKAGE_WITH_UPDATER=0`;
- updater-only DEB and RPM dependencies are removed.

The overlay deliberately fails if the expected upstream package structure has
changed. Fix the builder for the new upstream layout instead of silently
publishing an incorrectly packaged release.

`BUILD_SCHEMA_VERSION` in the workflow participates in release deduplication.
Increment it when a builder change must rebuild an otherwise unchanged upstream
source and DMG.
