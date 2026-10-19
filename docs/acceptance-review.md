# 验收准备复核 - 0.2.0

材料日期：2026-10-19；十月赛。结论：本地可执行技术门槛已通过；已知技术缺项已修复。公开仓库、注册表发布、远端 CI 与报名属于尚未执行的线上步骤。

## 官方要求对应

2026-10-19 重读官方 [十月赛页面源码](https://github.com/moonbitlang/Hackathon2026/blob/main/src/App.tsx)，JS 页面正文通过 raw GitHub 获取。官网列出的六项要求与本项目证据如下，测试数量不是官方门槛。

|官网要求|证据|状态|
|---|---|---|
|MoonBit 为主|根包核心、CLI 参数/报告、可执行示例；host.mbt 仅 Node I/O FFI|本地满足|
|仓库公开、开发可追踪|真实本地 Git 阶段历史|依用户要求未公开；不能以本地历史冒充公开记录|
|可运行、README、例子与必要测试|README、examples/plan、API.mbt.md、scripts/acceptance.py|本地满足|
|实质工作|原创标签事务、封面写出、padding 规划、流式宿主；见 CHANGELOG|本地有对应源码和验证|
|开源合规|MIT、THIRD_PARTY、合成 fixture 来源|本地满足|
|AI 可解释|docs/maintainer-guide.md、架构不变量、AI 范围|材料已准备；参赛者需自行掌握与讲解|

官网仍显示 2026-10-31 截止、十月最多提交三次、队伍不超过三人。正式章程链接本次工具未能读取，不补造额外条款；报名时按官方最终口径核对。

## 实际技术证据

|本项目质量检查|执行结果|证据|
|---|---|---|
|工具链与格式|moon 0.1.20260915 / moonc v0.10.13；fmt --check 通过|local-verification.json|
|公开 API|moon info 已审阅；新 RewritePlan、Document.plan、plan_metadata|pkg.generated.mbti|
|Wasm-GC / JS|各 23 测试（21 普通、2 文档）、check +73 --deny-warn / build 通过|local-verification.json|
|两后端行为|同一前缀规划示例 stdout 逐字节一致|examples/plan 与验证记录|
|原有真实媒体|44100 Hz / mono / 16 bit：标签、封面提取、3158 bytes 压缩音频、22050 bytes PCM 对照|local-verification.json|
|多格式真实媒体|22050/48000/96000 Hz，1/2/6 声道，16/24 bit 四组；压缩及 s32le PCM 一致|media-matrix.json|
|大文件|268439553 bytes 合成文件，后缀逐字节比对；大文件对已删除|streaming-cli.json|
|失败路径|短写、写异常、零进展、读异常、fsync 异常、源变化注入；失败清理、源不误写|streaming-cli.json|
|边界与无损属性|24 位上限、4096 块、畸形 UTF-8、36 位 samples、排序/占位符、80 组编辑矩阵|planning_test.mbt / metadata_test.mbt|
|实际归档消费|0.2.0 实际 zip 解压，两后端各 1 消费测试，解压 CLI inspect/plan|package-consumption.json|
|自动复现|同一 acceptance.py 入口；固定工具链 CI 配置|.github/workflows/ci.yml，尚未在线运行|
|申报与演示|精简 Markdown、一页 PDF、三分钟操作说明|submission-proposal.md / docs/demo.md|

上述 JSON 均在 docs/test-evidence。归档消费记录只留本地/Git，不嵌入自己所描述的 zip。核心/文档测试与独立消费计数分开。

## 0.1.0 到 0.2.0 修复

移除 CLI 256 MiB 整文件限制，改为前缀规划与分块复制；添加只读 plan 及 padding 入口；文件错误转 JSON，普通写出失败清理输出；检查源变化；拒绝重复 SEEKTABLE/CUESHEET 与乱序 seek 点；补充多声道/24 bit 和真实 I/O 故障验证。新发现的 Xcsa-ee/moonflac 已有元数据读取，本项目贡献明确为编辑和写出，详见生态报告。

范围：本库不验证音频帧 CRC/MD5，不解码图片，不解析 CUESHEET 内容；大文件测试的后缀为合成 bytes，不冒充可解码音频。文件并发变化检测不等于锁定或崩溃原子提交。

公开仓库/真实身份/namespace/远端 CI/确切 registry 消费以及正式报名仍待对应发布流程。官方审核结论须由赛事方给出。
