# 本地交付 0.3.0

2026-10-22，local/moonflactag，MIT。用户要求继续保留本地，未指定公开仓库/作者/注册表 namespace。

新增：目录批量预览/保存与逐文件结果；PNG/JPEG、按类型保留/替换/追加/删除及导出；元数据精确增量读取；结构化错误；临时文件无覆盖原子发布；第二编码路径和性能记录。原 parse/rewrite/plan API 与旧 --cover-png 全替换语义保留。

工具链仍为 moon 0.1.20260915、moonc v0.10.13+cbb11c36f、Node v24.19.0，Windows 实测。开发对照使用 FFmpeg、soundfile 0.13.1 / libsndfile 1.2.2 / numpy 1.26.4。运行库不依赖这些 Python/媒体工具。

两后端各 31 项测试（含 3 文档测试）、跨后端示例一致；FFmpeg 五组加 libsndfile 三组，复杂标签和 PCM 对照通过；批量/封面/发布竞态/强制退出、大文件与六类故障通过；实际归档消费各 2 项和解压 CLI 通过。一键入口 python scripts/acceptance.py。

性能是本机单次仪器化基线：64 MiB 合成文件 inspect 只读 8333 bytes；具体耗时、读取量、Node maxRSS 见 performance-baseline.json，不作普遍速度承诺。

归档 _build/publish/local-moonflactag-0.3.0.zip，含源码、公开 API、CLI、测试、必要素材、文档和复现脚本；排除研究原件、工具链、生成大文件、私有台账、Git、PDF 与 CI 配置。package-consumption.json 记录当次真实清单/结果，排除其自己描述的库归档。repository 待指定的打包提示如实保留。

保存要求目标目录支持硬链接。内容写完后原子发布目标，已有/竞态目标不覆盖；普通失败清理，强制退出可留私有临时文件，不承诺断电持久性。

历史：0.1.0（2026-10-17）首次本地交付，各后端 16 测试；0.2.0（2026-10-19）规划与分块复制，各后端 23 测试。历史记录保留，不补造公开时间。

待发布事项：真实身份与 namespace、公开开发记录、线上 CI、确切 registry 安装和正式报名/官方审核。
