# Codex Desktop Linux Builder
本仓库用于构建
[`ilysenko/codex-desktop-linux`](https://github.com/ilysenko/codex-desktop-linux)
的二进制包。可从release获取构建完成的deb, rpm或appimage包。  
本仓库会每日定时拉取上游源码并执行构建。版本号规则为Codex(现ChatGPT)版本号+构建时间戳。  
构建默认不包含更新器（因为上游项目的更新器只是拉取新源码重新编译，本仓库已经承担该职责）  
如果上游版本号未变动仅build号变化，则无需安装新版。全新安装时直接安装最新Release即可。  
其他问题请参考上游项目README  

暂无将产出包名更名为ChatGPT的计划。Desktop文件已默认是ChatGPT字样，不影响正常使用。  
暂无产出archlinux、nix包的计划。有需要可编写类似的workflow自行使用  

