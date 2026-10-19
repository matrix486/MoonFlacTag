# Mooncakes 生态调研

读取日期：2026-10-17。实际读取公开 API https://mooncakes.io/api-new/v0/modules ，返回 JSON 数组 3048 条；原始数据在忽略目录 research/modules.json。本次遍历模块名称与描述，不等于逐个审阅源码。该响应无分页字段。名称去重与抓取摘要由 research/summary.json 记录。

元数据关键词命中：AI 396、agent 64、workflow 19、parser 200、compiler 16、database 15、web 130、image 30、crypto 15、testing 19、devtool 3、wasm 75、visualization 9。按不区分大小写的子串匹配，有误报；数量不作为生态成熟度结论。

|模块与版本|registry created_at|已核对能力与边界|
|---|---|---|
|[Milky2018/moon_rodio@0.3.6](https://mooncakes.io/docs/Milky2018/moon_rodio@0.3.6)|2026-10-13T04:10:39.634997|native 播放与音频解码；代表性 API decode_flac_bytes 返回 PCM，调用 dr_flac C 桥；未见本项目所需标签改写 API|
|[NoahLiu/ffmpeg-mbt@0.1.0](https://mooncakes.io/docs/NoahLiu/ffmpeg-mbt@0.1.0)|2026-10-10T01:58:16.71249|libavformat/libavcodec 绑定，README API 为 Demuxer、decode_rgba、seek；需要宿主库|
|[LL728/moonvorbis@0.1.3](https://mooncakes.io/docs/LL728/moonvorbis@0.1.3)|2026-10-03T10:23:29.948467|纯 MoonBit Ogg/Vorbis 解码；与 native FLAC 标签写出不同|
|[shencangsheng513/moonmeta@0.1.0](https://mooncakes.io/docs/shencangsheng513/moonmeta@0.1.0)|2026-09-29T01:47:51.350508|JPEG/PNG/TIFF 的 EXIF 读写；非音频元数据|
|[mizchi/bit_apply@0.48.0](https://mooncakes.io/docs/mizchi/bit_apply@0.48.0)|2026-09-21T15:00:12.513534|已提供 unified diff apply，淘汰补丁候选|
|[caijiewei295/tzif-engine@0.1.0](https://mooncakes.io/docs/caijiewei295/tzif-engine@0.1.0)|2026-08-22T19:20:29.813163|TZif、UTC/local、DST、POSIX fallback，淘汰时区候选|

FLAC/Vorbis/taglib/ID3/metadata 同义词检索后，在本次索引范围未找到专门的纯 MoonBit FLAC 标签和封面编辑库；这不是全网不存在的证明。MoonFlacTag 增加的能力是无损元数据事务：大小端混合解析、重复标签语义、封面读写、填充预算、未知块与原音频 bytes 保留，提供跨 JS/Wasm-GC 的库，不绑定播放器。

下载/依赖统计未取得一致可靠结果；源码活动另见 GitHub 调研。

## 2026-10-19 针对性刷新

继续开发时取得 3114 条当前 registry 元数据，按 FLAC / Vorbis / taglib / ID3 刷新相关候选，未重新声称逐个审阅全部源码。新增 [Xcsa-ee/moonflac@0.1.1](https://mooncakes.io/docs/Xcsa-ee/moonflac@0.1.1)，created_at=2026-10-18T10:01:54.117105；LL728/moonvorbis 更新为 0.1.4（2026-10-17T02:34:21.945041）。

moonflac README 和 metadata_ext.mbt 实际提供 read_seektable / read_vorbis_comment / read_picture / read_application，不能再将 FLAC 元数据读取笼统声称为生态空白。其定位为解码和读取，未见标签/封面写出、padding 预算、前缀改写计划和文件保存 API。本项目独立价值收敛为编辑及写出，0.2.0 补上流式保存与预览；不复制解码器实现。源码对照见 GitHub 报告。
