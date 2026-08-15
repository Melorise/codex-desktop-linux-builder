# Codex Desktop Linux Builder

旧构建机已经停止。OpenAI 已提供官方 Linux deb，因此本仓库不再运行定时构建、
发布二进制包或上传二进制缓存。

构建机不再转换 macOS DMG，不再产出 deb、rpm 或 AppImage，也不会修改官方
应用、替换 Electron、执行 deb maintainer scripts 或添加社区功能。

## 分支

- `main`：项目迁移与归档说明。
- `nix`：公开的 Flake 源码，入口为
  `github:Melorise/codex-desktop-linux-builder/nix`。
- `archive/pre-official-linux-builder`：旧 DMG 构建机归档。
- `archive/pre-official-linux-nix-source`：旧 Nix 源码归档。

## Nix 接口

- Flake source：`github:Melorise/codex-desktop-linux-builder/nix`
- System：`x86_64-linux`
- Package output：`packages.x86_64-linux.chatgpt`
- Default package：`packages.x86_64-linux.default`
- App output：`apps.x86_64-linux.chatgpt`
- Executable：`chatgpt`
- Upstream deb：
  `https://persistent.oaistatic.com/codex-app-prod/linux/deb/latest/chatgpt_amd64.deb`

Flake 不提交自己的 `flake.lock`。官方 `latest` deb 与 `nixos-unstable` 的具体
revision 由使用者自己的根 Flake 和 lock-file 更新策略决定。如何接入 package
和 app 也由使用者自己的 Nix 配置决定。
