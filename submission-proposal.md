# MoonFlacTag - FLAC 元数据与批量整理库

0.3.0；2026-10-22；十月赛本地草稿。参赛者/GitHub ID、队员、仓库和 Mooncakes namespace 待指定。

面向音乐归档、媒体整理与上传工具：编辑标签和封面、批量预览与保存，逐字节保留原压缩音频，无需重新编码。

已有 rodio/FFmpeg/moonflac 提供播放、解码或读取；本项目原创贡献为类型化编辑、padding/前缀规划和宿主保存。生态报告保留实际检索日期及相近源码差异，不将元数据读取冒称独有能力。

已完成重复标签 set/add/remove、PNG/JPEG 与按类型封面替换/追加/删除/导出、目录递归批量与逐文件结果、元数据增量读取、固定错误字段、临时文件无覆盖原子发布。核心与 CLI 协调为 MoonBit，JS FFI 为宿主操作。

Wasm-GC / JS 各 31 测试（含 3 文档）、格式/check/build 通过；512 次突变、80 组编辑矩阵；FFmpeg 五组与 libsndfile 三组（8/16/24 bit、复杂多语言标签）PCM 对照一致。实际 zip 独立消费者各 2 测试，解压 CLI 可用。

批量/封面/发布竞态/强制退出与六类 I/O 注入通过。64 MiB 合成文件 inspect 实测只读 8333 bytes 元数据，记录耗时与 Node 峰值 RSS，不作普遍速度承诺。

MIT，生成素材和 AI 辅助范围明确。累计元数据 16 MiB/4096 块；不校验音频帧 CRC/MD5、不解码图片、不支持 Ogg-FLAC/ID3 前缀。保存要求硬链接支持；原子可见性不代表断电持久性。

三分钟演示见 docs/demo.md，实际证据见 docs/acceptance-review.md；同一验收入口与 CI、维护者讲解已准备。本地源码、验证、材料就绪，尚未公开发布、线上 CI、注册表安装或正式报名。

规则依据保留 [官方十月赛源码](https://github.com/moonbitlang/Hackathon2026/blob/main/src/App.tsx)，格式参考 [RFC 9639 §8](https://www.rfc-editor.org/rfc/rfc9639.html)。
