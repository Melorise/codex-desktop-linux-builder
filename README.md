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

Release workflow 会从与原生包相同的上游提交构建默认的 `x86_64-linux` Nix
flake 输出，并在发布 Release 前将完整闭包上传到 Cachix。Nix 构建使用独立、
未应用 builder 打包策略的上游 checkout，确保缓存路径与用户直接引用上游提交时
一致。

启用前需要完成以下仓库配置：

1. 在 Cachix 创建一个缓存。
2. 在 GitHub 仓库的 Actions variables 中设置 `CACHIX_CACHE_NAME`，值为缓存名。
3. 在 Actions variables 中设置 `CACHIX_PUBLIC_KEY`，值为缓存页面显示的 public signing key。
4. 在 Actions secrets 中设置 `CACHIX_AUTH_TOKEN`，值为该缓存的 write token。
5. 在 Cachix 缓存设置中启用 Garbage Collection。

缺少任一配置时 Nix job 会失败，Release 不会发布。workflow 还会校验上游
`flake.nix` 固定的 DMG 哈希与本次 Release 使用的 DMG 完全一致，避免上传与
Release 内容不对应的缓存。

workflow 使用固定 pin `codex-desktop-x86_64-linux`，并设置
`--keep-revisions 1`。每次成功上传会让上一版失去 pin；Cachix Garbage
Collection 随后可以删除不再被最新版引用的旧闭包。GitHub Release 本身不会
删除，但旧 Release 对应的 Nix 包在缓存回收后会回退到本地构建。为控制免费版
容量，功能变体和 installer 不会上传到 Cachix。

Release notes 会生成固定到对应上游提交的声明式 NixOS flake 配置。先在
`flake.nix` 中添加 input：

```nix
{
  inputs.codex-desktop-linux = {
    url = "github:ilysenko/codex-desktop-linux/<UPSTREAM_SOURCE_SHA>";
    inputs.nixpkgs.follows = "nixpkgs";
  };
}
```

再将 module 和缓存设置加入对应的 `nixosSystem`：

```nix
nixosConfigurations.my-host = nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  modules = [
    ./configuration.nix
    inputs.codex-desktop-linux.nixosModules.default
    ({ pkgs, ... }: {
      nix.settings = {
        extra-substituters = [ "https://<CACHIX_CACHE_NAME>.cachix.org" ];
        extra-trusted-public-keys = [ "<CACHIX_PUBLIC_KEY>" ];
      };

      programs.codexDesktopLinux = {
        enable = true;
        cliPackage = pkgs.codex;
      };
    })
  ];
};
```
