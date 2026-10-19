# 架构与不变量

parse 从 fLaC 签名逐块读取，先检查剩余长度和预算，再复制 payload。首块为 34 字节 STREAMINFO；STREAMINFO / VORBIS_COMMENT / SEEKTABLE / CUESHEET 各至多一个，127 类型拒绝，7..126 不透明保留。padding 全零、APPLICATION 至少四字节。SEEKTABLE 长度为 18 的倍数，按 unsigned 64-bit sample 严格排序且唯一，重复 placeholder 仅在末尾；其余字段和目标帧不解释。

Reader 在块内处理 u32：Vorbis comment 小端，PICTURE 大端。长度先用 UInt 比较剩余 bytes 再转 Int，count 先以每条至少四字节限制循环。文本严格 UTF-8，输出前检查 UTF-16 surrogate。

标签键为 ASCII 0x20..0x7d，排除等号。按第一个等号分割，匹配忽略 ASCII 大小写。Set 删除全部同名条目后追加一条，Add 追加，Remove 删除全部。vendor 保留；无标签时新建 MoonFlacTag/0.2.0。

PICTURE 类型 0..20、media type 为可打印 ASCII、description 为 UTF-8，宽高等字段为 UInt32。type 1 要求 32×32 PNG，type 1/2 各最多一个；二进制/URI 均不透明，不验证实际图片与声明尺寸吻合。

Document 字段私有，blocks/comments/pictures 返回新数组。plan 只编码元数据，不拼接音频。rewrite 调用同一个 plan，再追加原音频；plan_metadata 对精确前缀额外拒绝尾随 bytes，避免宿主误用。未编辑块及相对顺序保留；替换封面时将新封面追加到非 padding 块末尾；padding 合并，最后块标志重建。

保持偏移预算：original_offset - (4 + sum(4 + payload_length))。0 不需 padding，>=4 可放块头与数据，负数或 1..3 返回 NoSpace。音频边界是元数据链末尾，不通过扫描同步字猜测。SEEKTABLE 偏移相对于第一音频帧，因此仅改变元数据长度时不重写它。

CLI Host 只负责有界读取与复制，不解析 FLAC 字段。先固定打开源描述符，读取最多 16 MiB 前缀交给 MoonBit；doc.plan 生成前缀，主机再从 old_audio_offset 以 1 MiB chunks 复制到新文件。prefix 中可能含少量音频，plan 会排除它们，实际后缀始终从已打开的原文件复制。

输出使用 wx 独占创建。writeAll 处理短写；复制前后检查源 size / mtimeNs / ctimeNs；fsync 失败也视为失败。失败时只清理本次创建、身份仍匹配的输出，已有目标不覆盖。defer 关闭源。普通 I/O 错误转成 JSON，不把原始宿主异常作为成功结果。并未锁定源或承诺崩溃原子性。

核心 MoonBit API 与 Node 文件 I/O 的边界明确；无 FFmpeg 运行依赖，外部 FFmpeg 仅作为独立测试 oracle。
