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

The Flake extracts the official deb and applies only the ELF interpreter,
RUNPATH, shebang, and launch-environment changes required on NixOS. It does not
use `buildFHSEnv`, so the application is not placed inside an additional
bubblewrap sandbox. Bubblewrap is exposed only through the application wrapper
so the bundled Codex CLI can create its own sandbox; users do not need to add
it to the system profile.

The official `app.asar`, product name, icon, desktop entry, and bundled Codex
CLI receive no feature or branding changes. ELF inventory, patching, and audit
logic comes from the upstream `codex-desktop-linux` Nix compatibility layer;
see `THIRD_PARTY_NOTICES.md` for its source and license.
