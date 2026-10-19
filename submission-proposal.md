# MoonFlacTag - FLAC 无损元数据编辑库

0.2.0；2026-10-19；十月赛本地申报草稿。参赛者/GitHub ID、队员、仓库和 Mooncakes namespace 待指定。

为 MoonBit 音乐归档、媒体整理与上传工具提供标签、封面和 padding 编辑；保存时逐字节保留原压缩音频，无需重编码。

初次检查 3048 条模块元数据，10 月 19 日针对 3114 条当前元数据刷新；已有 rodio/FFmpeg 与新增 moonflac 提供播放、解码或读取，本项目独立贡献为标签事务、封面写出、偏移预算、元数据规划与分块保存。原创实现，依据 RFC 9639，详见生态报告。

已实现：重复 Vorbis 标签 set/add/remove、PICTURE、STREAMINFO、未知块保留、padding 三策略、RewritePlan、只读预览与 Node CLI。核心格式/编辑/报告为 MoonBit，JS FFI 仅有界文件 I/O。普通写出失败清理，源变化报错。

Windows 实测 Wasm-GC / JS 各 23 项测试（含 2 文档测试），格式/check/build 通过；两后端示例相同，实际归档独立消费各 1 测试与解压 CLI 成功。FFmpeg/ffprobe 对照五组音频，覆盖 16/24 位与 1/2/6 声道；268439553 bytes 合成后缀和六类 I/O 故障验证通过。

MIT，合成素材来源清楚，AI 辅助范围已披露，参赛者需理解并负责。累计元数据 16 MiB/4096 块；不验证音频帧 CRC/MD5、不解码图片、不支持 Ogg-FLAC/前置 ID3，不承诺崩溃原子提交。

三分钟演示见 docs/demo.md，验收证据见 docs/acceptance-review.md。维护以失败样例回归、API 版本化与宿主集成为主；同一验收入口的固定工具链 CI 配置已准备。

本地源码、素材、文档与真实阶段历史就绪；未公开发布、运行远端 CI 或正式报名。需补真实身份与发布证据后再正式申报。

规则：[官方十月赛源码](https://github.com/moonbitlang/Hackathon2026/blob/main/src/App.tsx)；技术依据：[RFC 9639 §8](https://www.rfc-editor.org/rfc/rfc9639.html)。
