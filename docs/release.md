# 本地交付 0.2.0

2026-10-19，模块 local/moonflactag，MIT。保留本地，GitHub owner/repo、真实作者、Mooncakes 账号/namespace 和参赛者资料待指定。

本版新增元数据 RewritePlan、只读 plan 命令、分块文件保存、普通错误清理和源变化检测，补齐 seektable 顺序和 singleton 约束。详见 CHANGELOG。

工具链：moon 0.1.20260915 (2e1a46d)、moonc v0.10.13+cbb11c36f、moonrun 0.1.20260915；Windows 上实测，Node v24.19.0。CI 准备使用官方 0.10.13+cbb11c36f 发行归档，对应 Linux 二进制及 core URL 已可访问。

|门槛|实际结果|
|---|---|
|Wasm-GC / JS|各 23 测试（含 2 文档测试）；fmt/check +73/deny-warn/build 通过|
|跨后端示例|规划结果 stdout 相同|
|真实媒体|原有素材加四组媒体，标签/封面/压缩音频/PCM 对照通过|
|宿主 I/O|268439553 bytes 合成文件；六类故障注入通过|
|实际分发|真实 zip 独立工作区双后端各 1 消费测试；解压 CLI inspect/plan 成功|

一键复现 python scripts/acceptance.py。详情见 docs/test-evidence 下的 local-verification.json、media-matrix.json、streaming-cli.json。package-consumption.json 记录当次实际文件数和 zip 大小，只留本地/Git，排除其自己描述的归档。

归档：_build/publish/local-moonflactag-0.2.0.zip。含源代码、API、CLI 源码、素材、文档、验证脚本和许可；排除研究原件、大型中间素材、工具链、Git、私有台账、PDF、CI 配置。repository 未指定的打包提示如实保留，不填造 URL。

提交历史保留真实阶段：0.1.0 调研/核心/媒体验证/申报材料；0.2.0 的功能、验证和材料在本地继续提交，不补造公开日期。0.1.0 于 2026-10-17 本地完成、各后端 16 测试，属于历史结果。

线上发布、远端 CI、registry 确切版本安装、正式报名与官方审核均未执行。CI 配置已准备，在公开阶段运行后再补正式证据。
