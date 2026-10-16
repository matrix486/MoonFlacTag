# 架构与不变量

`parse` 从 fLaC 签名开始逐块读取，先检查剩余长度与累计预算，之后复制 payload。首块必须是 34 字节 STREAMINFO，STREAMINFO/VORBIS_COMMENT 至多一个，127 类型拒绝；7..126 保留。padding 必须全零，APPLICATION 至少 4 字节，SEEKTABLE 长度为 18 的倍数。CUESHEET 和保留类型按不透明 bytes 保存。

`Reader` 在块内读取 u32，Vorbis comment 是 little-endian，PICTURE 是 big-endian。长度先以 UInt 比较剩余 bytes，再转换为 Int，避免高位长度变为负数。count 用最少四字节/条的条件限制循环。文本严格 UTF-8；编码前检查 UTF-16 surrogate，避免宿主提供畸形字符串时触发编码器 panic。

标签键遵循 RFC 9639 §8.6 的 ASCII 0x20..0x7d（排除等号），值按第一个等号切分，重复键保留顺序。Set 删除同名所有条目后追加一条；Add 追加；Remove 删除所有。vendor 从原块继承，原文件无标签时新建 vendor=MoonFlacTag/0.1.0。

PICTURE 类型限制为 0..20，media type 为可打印 ASCII，description 为 UTF-8。宽/高/位深/颜色保留 UInt32；type 1 必须是 32×32 PNG，type 1/2 各最多一个。图片数据、链接 URI 都是不透明 bytes；不推断实际图片内容与声明尺寸一致。

Document 字段私有。`blocks()`、comments/pictures 解析结果返回新数组。Bytes 是不可变值。rewrite 按 edit 顺序创建新标签，保留未编辑块及其相对顺序；替换封面时移除全部旧 PICTURE 后将新封面追加到非 padding 块末尾。padding 被合并或删除，最后块标志重新生成。音频数据只从原 Document 的音频后缀复制。

音频偏移是元数据链末尾，不是通过扫描音频同步字识别。保持 offset 的预算公式是 `original_offset - (4 + sum(4 + payload_length))`；0 直接完成，>=4 可添加 padding，其余返回 NoSpace。只保证音频 bytes 保留，不声称对任意输入完成帧完整性或全格式合规验证。

Node CLI 的 JS FFI 只负责参数、最多 256 MiB 文件读取、新路径保存和错误输出。核心格式逻辑、编辑规划、JSON 内容由 MoonBit 执行。输出是新文件，已有路径不覆盖。库调用方自行负责持久化与并发控制。
