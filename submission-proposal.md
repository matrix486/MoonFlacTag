# MoonFlacTag - FLAC 无损元数据编辑库

版本 0.1.0；材料日期 2026-10-17；十月赛本地申报草稿。
参赛者/GitHub ID、队员、公开仓库、Mooncakes namespace：待指定。

为 MoonBit 媒体整理、音乐归档与上传工具提供 FLAC 标签、封面和填充区编辑；修改元数据时保留原压缩音频 bytes，不需要解码重编码。

读取 3048 条 Mooncakes 模块元数据并检查相关 GitHub API/README/代表实现；已有 rodio/FFmpeg 侧重播放解码，本项目新增纯 MoonBit 标签事务、PICTURE 写出与偏移预算规划。原创实现，格式依据 RFC 9639；调研范围与限制见生态报告。

已完成：STREAMINFO、重复 Vorbis 标签 set/add/remove、封面替换/删除、未知块保留、padding compact/exact/preserve-offset、结构化错误、公开库 API 和 Node CLI。核心在 MoonBit；JS FFI 仅文件和参数适配。

Windows 上 moon 0.1.20260915 验证 Wasm-GC/JS，各 16 项测试（含 1 文档测试）、格式/check/build 通过；实际归档独立消费各 1 项测试，解压 CLI 可用。FFmpeg/ffprobe 对照标签、封面、压缩音频与解码 PCM 一致。

MIT，合成音频/色块来源清楚，AI 辅助实现与材料；参赛者需理解关键逻辑。全文件驻留内存，不提供音频帧/CRC/MD5 校验或图片解码，不支持 Ogg-FLAC/ID3 前缀。

三分钟演示见 docs/demo.md，详细证据见 docs/acceptance-review.md。后续维护围绕失败样例回归、API 版本化和宿主集成。

源码、素材、验证记录与本地开发历史已保存；未公开发布、运行远端 CI 或正式报名。线上链接与真实身份补齐后方可提交正式申报。

规则来源：[官方十月赛页面源码](https://github.com/moonbitlang/Hackathon2026/blob/main/src/App.tsx)；技术依据：[RFC 9639 §8](https://www.rfc-editor.org/rfc/rfc9639.html)。
