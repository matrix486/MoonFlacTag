# 本地交付 0.1.0

2026-10-17，MoonFlacTag 0.1.0。状态：仅本地保存。模块占位 `local/moonflactag`；公开仓库、Git 真实作者、Mooncakes namespace 与参赛者待指定。本地 Git 中性身份用于记录实际开发阶段。

交付包括纯 MoonBit 库、Node CLI、测试、可执行 API 文档、合成音频与封面、生态调研、复核报告、三分钟演示说明、申报草稿和一页 PDF。核心功能提交为 `883856c`，后续文档/验证提交以本地 Git 历史为准。

验证工具链：moon 0.1.20260915 (2e1a46d)、moonc v0.10.13+cbb11c36f、moonrun 0.1.20260915；Windows 上实测；Node v24.19.0。FFmpeg 2026-03-09-git-9b7439c31b 用于外部媒体对照。

|范围|结果|
|---|---|
|Wasm-GC|check +73 / deny-warn、16 测试（含 1 文档测试）、build 通过|
|JavaScript|check +73 / deny-warn、16 测试（含 1 文档测试）、build 通过|
|媒体与 CLI|默认边界保持、标签读取、封面提取、未知块保留、压缩音频/PCM bytes 对照、错误退出与不覆盖路径通过|
|本地归档|moon package 实际 zip，解压后 Wasm-GC/JS 各 1 消费测试、解压 CLI 调用通过|

完整数值见 [本地验证记录](test-evidence/local-verification.json)。归档消费脚本将当次的文件数、结果写入本地记录 `docs/test-evidence/package-consumption.json`；该记录按渠道排除规则不嵌入它自己所描述的库归档。实际归档位于 `_build/publish/local-moonflactag-0.1.0.zip`，本地可复跑。

打包预期含源码、公开接口、CLI 源码、必要 fixture、许可证、文档与复现脚本；排除 research/、release-local/、demo-output/、工具链/构建结果、Git 私有记录和 PDF。未指定 repository 导致的打包 metadata 提示如实保留，没有填造仓库 URL。

公开发布、远端 CI、注册表安装、报名与官方审核均未执行。本地测试和消费结果不代表这些线上步骤完成。
