# ChatGPT for Nix

This branch packages the official OpenAI Linux deb for Nix. It does not patch
the application, replace Electron, add community features, or execute the deb
maintainer scripts.

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
