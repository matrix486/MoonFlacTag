# Mooncakes 生态调研

读取日期：2026-10-17。实际读取公开 API https://mooncakes.io/api-new/v0/modules ，返回 JSON 数组 3048 条；原始数据在忽略目录 research/modules.json。本次遍历模块名称与描述，不等于逐个审阅源码。该响应无分页字段。名称去重结果由 research/summary.json 记录。

元数据关键词命中：AI 396、agent 64、workflow 19、parser 200、compiler 16、database 15、web 130、image 30、crypto 15、testing 19、devtool 3、wasm 75、visualization 9。按不区分大小写的子串匹配，有误报；数量不作为生态成熟度结论。

|模块与版本|registry created_at|已核对能力与边界|
|---|---|---|
|[Milky2018/moon_rodio@0.3.6](https://mooncakes.io/docs/Milky2018/moon_rodio@0.3.6)|2026-10-13T04:10:51.019142|native 播放与音频解码；代表性 API decode_flac_bytes 返回 PCM，调用 dr_flac C 桥；未见本项目所需标签改写 API|
|[NoahLiu/ffmpeg-mbt@0.1.0](https://mooncakes.io/docs/NoahLiu/ffmpeg-mbt@0.1.0)|见本地 registry 原始响应|libavformat/libavcodec 绑定，README API 为 Demuxer、decode_rgba、seek；需要宿主库|
|[LL728/moonvorbis@0.1.3](https://mooncakes.io/docs/LL728/moonvorbis@0.1.3)|见原始响应|纯 MoonBit Ogg/Vorbis 解码；与 native FLAC 标签写出不同|
|[shencangsheng513/moonmeta@0.1.0](https://mooncakes.io/docs/shencangsheng513/moonmeta@0.1.0)|见原始响应|JPEG/PNG/TIFF 的 EXIF 读写；非音频元数据|
|[mizchi/bit_apply@0.48.0](https://mooncakes.io/docs/mizchi/bit_apply@0.48.0)|2026-09-21T15:00:12.513534|已提供 unified diff apply，淘汰补丁候选|
|[caijiewei295/tzif-engine@0.1.0](https://mooncakes.io/docs/caijiewei295/tzif-engine@0.1.0)|见原始响应|TZif、UTC/local、DST、POSIX fallback，淘汰时区候选|

FLAC/Vorbis/taglib/ID3/metadata 同义词检索后，在本次索引范围未找到专门的纯 MoonBit FLAC 标签和封面编辑库；这不是全网不存在的证明。MoonFlacTag 增加的能力是无损元数据事务：大小端混合解析、重复标签语义、封面读写、填充预算、未知块与原音频 bytes 保留，提供跨 JS/Wasm-GC 的库，不绑定播放器。

下载/依赖统计未取得一致可靠结果；源码活动另见 GitHub 调研。
