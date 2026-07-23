# Codex Desktop Linux Builder
本仓库用于构建
[`ilysenko/codex-desktop-linux`](https://github.com/ilysenko/codex-desktop-linux)
的二进制包。可从release获取构建完成的deb, rpm或appimage包。  
本仓库会每日定时拉取上游源码并执行构建。版本号规则为Codex(现ChatGPT)版本号+构建时间戳。  
构建默认不包含更新器（因为上游项目的更新器只是拉取新源码重新编译，本仓库已经承担该职责）  
如果上游版本号未变动仅build号变化，则无需安装新版。全新安装时直接安装最新Release即可。  
其他问题请参考上游项目README  

暂无将产出包名更名为ChatGPT的计划。Desktop文件已默认是ChatGPT字样，不影响正常使用。  
暂无产出archlinux包的计划。

## Nix 与 Cachix

Release workflow 会从与原生包相同的上游提交构建 `x86_64-linux` Nix
flake 输出，并在发布 Release 前将完整闭包上传到 Cachix。Nix 构建使用独立、
未应用 builder 打包策略的上游 checkout，确保缓存路径与用户直接引用上游提交时
一致。

启用前需要完成以下仓库配置：

1. 在 Cachix 创建一个缓存。
2. 在 GitHub 仓库的 Actions variables 中设置 `CACHIX_CACHE_NAME`，值为缓存名。
3. 在 Actions secrets 中设置 `CACHIX_AUTH_TOKEN`，值为该缓存的 write token。

缺少任一配置时 Nix job 会失败，Release 不会发布。workflow 还会校验上游
`flake.nix` 固定的 DMG 哈希与本次 Release 使用的 DMG 完全一致，避免上传与
Release 内容不对应的缓存。

发布后可按 Release notes 中记录的上游提交使用：

```bash
cachix use <CACHIX_CACHE_NAME>
nix run github:ilysenko/codex-desktop-linux/<UPSTREAM_SOURCE_SHA>
```
