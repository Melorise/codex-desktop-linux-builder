# ChatGPT for Nix

This branch packages the official OpenAI Linux deb for Nix. It does not patch
the application code, replace Electron, add community features, or execute the
deb maintainer scripts.

## Interfaces

- Flake source: `github:Melorise/codex-desktop-linux-builder/nix`
- Supported system: `x86_64-linux`
- Package output: `packages.x86_64-linux.chatgpt`
- Default package: `packages.x86_64-linux.default`
- App output: `apps.x86_64-linux.chatgpt`
- Executable: `chatgpt`
- Upstream input: `https://persistent.oaistatic.com/codex-app-prod/linux/deb/latest/chatgpt_amd64.deb`

This branch does not commit a lock file. Consumers lock and update the official
`latest` deb and `nixos-unstable` inputs through their own root Flake.

## Packaging boundary

The Flake extracts the official deb without inspecting or patching its internal
ELF inventory. It runs the payload in a `buildFHSEnv` containing the required
runtime libraries and Bubblewrap. Users do not need to add Bubblewrap to the
system profile.

The official `app.asar`, product name, icon, desktop entry, and bundled Codex
CLI receive no feature or branding changes.
