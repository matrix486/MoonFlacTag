# 验收准备复核 - 0.4.0

材料日期：2026-10-23。完整本地验收已通过；正式发布目标为 matrix486/MoonFlacTag 与 matrix486/moonflactag@0.4.0。远端 CI 与 registry 消费结果完成后补入发布记录，官方报名/审核未执行。

官网要求沿用 2026-10-19 已核对的 [十月赛页面源码](https://github.com/moonbitlang/Hackathon2026/blob/main/src/App.tsx)：MoonBit 主体、公开追踪、可运行/文档/测试、实质工作、开源合规、参赛者理解 AI 产物。本轮是同一项目继续完善，不重新声称查过新的章程。发布 GitHub ID 与 Mooncakes 账号均已由用户指定为 matrix486；其他报名资料不猜填。

|要求/质量门槛|证据|状态|
|---|---|---|
|MoonBit 主体|核心解析/编辑/图片头/前缀规划与 CLI 协调均为 MoonBit；JS 为 I/O 桥|本地满足|
|公开持续开发|真实本地 Git 历史|本地阶段历史保留；2026-10-23 起按用户授权公开，不倒填公开时间|
|运行、文档、测试|README、API.mbt.md、examples/plan、acceptance.py|通过|
|实质新增|批量、完整封面操作、原子发布、诊断、增量读取、独立语料|对应源码和 CHANGELOG|
|许可与来源|MIT、THIRD_PARTY、本地生成素材|材料完整|
|AI 可解释|架构与 maintainer-guide|讲解材料完整，仍需参赛者亲自掌握|

## 实际执行

|检查|结果|记录|
|---|---|---|
|格式/检查/构建|Wasm-GC / JS，fmt / check +73 --deny-warn / build 通过|local-verification.json|
|核心/文档|每后端 31 项：28 普通、3 文档；512 次突变与 80 组编辑矩阵在相应命名测试内|metadata/planning/artwork 测试与 API.mbt.md|
|跨后端行为|相同 plan 示例输出逐字节一致|local-verification.json|
|FFmpeg 媒体|原有五组，覆盖 mono/stereo/6ch、16/24 bit，标签/封面/压缩音频/PCM 对照|local-verification.json、media-matrix.json|
|第二编码路径|libsndfile FLAC 三组 8/16/24 bit，约 98 KiB 多语言/重复/空值/长标签；两套解码 PCM 一致|compatibility-corpus.json|
|批量流程|预览不写、递归/排序/部分失败、目标冲突、根路径隔离、符号链接跳过|product-workflows.json|
|封面流程|PNG/JPEG 头、选择性替换/追加/删除、逐字节导出、旧选项兼容|product-workflows.json|
|保存协议|写完前目标不可见、竞态目标保留、链接失败清理、强制退出无半成品目标|product-workflows.json|
|大文件/旧故障|268439553 bytes 合成后缀；短写、零进展、读写失败、fsync 与源变化六类注入|streaming-cli.json|
|性能记录|约 64 MiB 合成文件 inspect 只读 8333 bytes；记录含启动时间及 Node maxRSS|performance-baseline.json|
|实际分发|0.4.0 zip 解压，每后端 2 消费测试，解压 CLI inspect/plan/batch plan 成功|package-consumption.json|
|完整使用流程|默认空间自动回退、严格模式覆盖、创建父目录、批量重跑/进度、UTF-8 报告与报告竞态|cli-workflows.json|
|独立运行包|只需 Node，真实 zip 跨目录运行；实际 tgz 离线安装、命令入口和卸载|cli-distribution.json|
|统一复现|python scripts/acceptance.py 与同入口 CI 配置|本地通过，远端尚未运行|
|申报演示|精简 Markdown、三分钟步骤与新一页 PDF|本地材料|

JSON 记录均在 docs/test-evidence，实际归档消费记录按渠道边界不嵌入它自己描述的 zip。本轮文件保存集成因受限沙箱禁止硬链接，使用同一项目目录的本机权限执行；未联网、未外发。

## 本轮补齐与边界

0.3.0 的批量、封面、兼容语料及保存验证保留。0.4.0 按日常命令行使用补齐独立启动/离线安装、自动空间、批量重跑和进度、UTF-8 报告、父目录创建和完整使用手册。计数、循环次数、编码器语料、消费测试分别报告，不相加为采用量。

批量逐文件提交，不是整批回滚；预览不冻结输入。硬链接不支持/被环境禁止时返回错误，不降级覆盖。强制退出可留私有临时文件，原子可见性不等于断电持久性。源未锁定，不校验音频帧 CRC/MD5、不解码图片，不支持 Ogg-FLAC/前置 ID3。语料是本地生成信号和独立元数据，不冒充第三方真实录音全集。

公开仓库和发布身份已确定，线上 CI、确切 registry 消费结果见 release.md；官方报名/审核未执行。
