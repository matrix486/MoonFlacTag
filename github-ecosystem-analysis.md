# GitHub 生态调研

读取日期：2026-10-17。搜索 MoonBit/FLAC/metadata/Vorbis comment/picture、MoonBit/patch/unified、MoonBit/TZif、MoonBit/WebM/EBML，并检查官方 awesome-moonbit 入口。搜索索引有覆盖限制，空结果只说明已检索范围。

|仓库|API/代表文件|最近 pushed_at（读取 API 原字段）|stars / open issues|
|---|---|---|---|
|[moon_rodio](https://github.com/moonbit-community/moon_rodio)|README、decoder/flac_decoder_native.mbt；decode_flac_bytes → DecodedSamples，C 桥负责解码|2026-10-13T04:13:48Z|0 / 0|
|[moonbit-libyue](https://github.com/lb091188/moonbit-libyue)|modules/ffmpeg-mbt/README.md：动态链接 FFmpeg、视频解码/seek|2026-10-16T16:24:15Z|2 / 0|
|[moonbit-HexEditor](https://github.com/R00TK17/moonbit-HexEditor)|README：通用十六进制编辑与音频格式识别，包括 FLAC；未据此推断专用标签事务 API|2026-09-05T17:07:47Z|0 / 0|
|[moonvorbis](https://github.com/LL728/moonvorbis)|README、源码目录：Ogg/Vorbis 解码器|2026-10-03T10:23:43Z|0 / 0|
|[bit-vcs](https://github.com/mizchi/bit-vcs)|modules/bit_apply/src/apply.mbt；成熟同需求补丁实现，淘汰候选|2026-09-21T14:58:48Z|74 / 6|
|[moonav1](https://github.com/0717lee/moonav1)|README 提供 WebM/Matroska 轨道读取与分块容器输入，淘汰通用 demux 候选|2026-10-01T03:57:22Z|0 / 0|

API 返回的 pushed_at 是仓库活动，不能替代某功能的提交时间。下载量与实际采用情况未知。相关三个媒体仓库的 open_issues_count 为 0，不据此制造未解决需求；未读到专用标签编辑 roadmap。本项目需求来自可复现任务：修改标签而保持压缩帧与未知元数据，FFmpeg 用作独立对照。

本项目参考 [RFC 9639](https://www.rfc-editor.org/rfc/rfc9639.html) §8，独立实现元数据编辑。未复制上述项目代码。已有 C/Rust/JS FLAC 标签工具是成熟外部方案，MoonBit 的价值为可嵌入、可编译到 Wasm 的原生库，而非声称发明 FLAC 标签格式。

与本批前两个项目的边界：本项目处理文件内音频元数据，不使用 Netlink、不读取 cgroup、不共享其核心实现或验证材料。私有目录与账号信息只在本地台账。

## 2026-10-19 相近实现刷新

[Xcsa-ee/moonflac](https://github.com/Xcsa-ee/moonflac) 的 README 与 [metadata_ext.mbt](https://github.com/Xcsa-ee/moonflac/blob/master/metadata_ext.mbt) 已读取。GitHub pushed_at=2026-10-18T10:34:34Z，stars=0，open_issues_count=0。仓库不跟踪根 pkg.generated.mbti，本次按实际公开函数声明检查。

公开函数包括 read_seektable / read_vorbis_comment / read_picture / read_application，属于元数据读取与音频解码；README 声明不提供编码器/标签写入。未见元数据写出和保存事务接口，不能据此虚构上游未解决 issue。MoonFlacTag 继续独立实现编辑、padding、RewritePlan 和 Node 分块保存；两者功能可互补。没有移植或导入该项目代码。
