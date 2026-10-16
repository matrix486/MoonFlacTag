# 本地验收准备复核

材料日期：2026-10-17；十月赛；MoonFlacTag 0.1.0。公开仓库、真实作者与 Mooncakes namespace 待指定。

总体状态：本地技术交付和申报草稿就绪；尚未公开发布、报名或取得官方审核结果。

规则依据为当天读取的官方 [App.tsx](https://github.com/moonbitlang/Hackathon2026/blob/main/src/App.tsx)。10 月 31 日报名与验收截止、十月最多提交 3 次、每队不超过 3 人、公开持续开发、MoonBit 主体、可复现代码/README/测试/演示、开源合规属于官网要求。下列测试和归档验证为本项目质量措施，不冒充赛事逐项强制条件。

|检查|证据|本地结果|
|---|---|---|
|用户需求与独立贡献|project-proposal.md、两份生态调研、竞争分析|选定原生 FLAC 元数据编辑，淘汰已有直接竞品方向|
|主要 MoonBit 实现|根包 wire/comments/picture/document/edit，生成 mbti|核心解析与编辑均为 MoonBit；JS FFI 仅宿主 I/O|
|工具链|docs/test-evidence/local-verification.json|moon 0.1.20260915；moonc v0.10.13；Node v24.19.0|
|格式/检查/构建|scripts/verify.py|fmt --check；Wasm-GC/JS check +73 --deny-warn、build --deny-warn 通过|
|公共接口与示例|metadata_test.mbt、API.mbt.md、pkg.generated.mbti|两后端各 16 项测试，其中 1 项文档测试；moon info 已生成并审阅|
|真实媒体|合成 sine FLAC、有效 PNG、FFmpeg/ffprobe|标签、封面、PCM 与压缩后缀对照通过|
|音频保持|原边界 8333、音频 3158 bytes、PCM 22050 bytes|默认 edit 后边界不变；音频和解码 PCM 逐字节一致|
|错误与资源边界|截断循环、非法 u32 长度、重复块、padding、CLI 错误测试|通过；核心累计元数据 16 MiB/4096 块，CLI 文件 256 MiB|
|实际归档消费|scripts/verify_package.py|真实 zip 解压后独立工作区，两后端各 1 项消费测试；解压 CLI 成功|
|许可证与素材|LICENSE、THIRD_PARTY.md、fixtures/README.md|MIT；合成媒体、独立实现；无第三方实现代码导入|
|申报与演示|submission-proposal.md、docs/demo.md、一页 PDF|本地草稿；真实身份和线上链接待补|

本期新增为 FLAC 标签事务、封面写出、padding 预算规划和不透明块/音频保留；不是音频解码器。AI 辅助范围已披露，参赛者需理解并维护。测试数量按库/文档与独立消费分别记录，不相加为采用量。

边界：全文件内存处理；音频帧、MD5/CRC 不由本库验证；不解码图片、不请求链接图片；CUESHEET 与 SEEKTABLE 不做完整语义检查；native 后端不在本版支持声明中。真实 fixture 的解码对照不能证明任意输入的音频有效。

后续发布阶段：指定仓库/账号/作者、替换本地模块名、核对正式链接及分发清单、实际远端 CI、确切注册表版本安装。公开持续开发要求尚未满足；本地历史不能补造为公开历史。正式报名所需身份和官方审核由相应流程确认。
