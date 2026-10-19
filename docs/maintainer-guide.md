# 维护者需要掌握的设计

## 为什么不重编码也能修改标签？

native FLAC 元数据链在音频帧前。MoonFlacTag 只重建链，把音频起始点之后的原字节交还调用方。CLI 从已打开的原文件描述符分块复制后缀，因此不需要编解码器。字节保留不等于证明原音频有效。

## 为什么有两种端序？

块头三字节长度、STREAMINFO 与 PICTURE 按大端，Vorbis comment 的 vendor/entry 长度和条目数按小端。Reader 使用显式 little 参数；测试用手工 bytes 而非共享生产编码器作为关键 oracle。

## u32 为什么先比较再转换？

0xffffffff 转有符号 Int 会变为负数，可能绕过长度检查。实现先以 UInt 比较剩余 bytes，再进行安全范围内转换；count 先通过每条最少四字节限制。

## 为什么剩余 1..3 字节也报 NoSpace？

FLAC padding 也需要四字节块头。不能插入未定义的裸字节；PreserveOffset 不会擅自挪动音频。Compact 或 Exact 由调用方明确选择。

## 重复键、未知块和 seektable 如何处理？

键匹配只忽略 ASCII 大小写，允许多个 ARTIST；Set 删除同名后追加，Add 保留已有，Remove 删除全部。非目标块 payload 保留，padding 合并。seektable 的偏移相对第一音频帧，移动元数据并不改变这个基准；检查样本排序和占位符，但不验证目标帧。

## plan、rewrite 与 CLI 的区别？

Document.plan 返回前缀，rewrite 追加内存中的音频；plan_metadata 只接受精确前缀。CLI 用有界前缀调用 plan，再从原描述符复制。JS FFI 执行 fs 操作，业务格式、标签与输出规划在 MoonBit。

## 文件保存保证到哪里？

新路径 wx 创建，不覆盖已有目标；短写重试，普通失败清理自己创建的文件。源 size/mtimeNs/ctimeNs 变化时失败。未锁定源；强制终止/断电可能留文件，不声称原子事务。外层需要更强事务时应自行管理临时文件与发布步骤。

## 如何解释测试？

23 项是有意义的命名测试，部分包含多个边界或 80 组属性矩阵，不把循环次数计成独立测试。核心两后端、独立消费各一项、五组 FFmpeg 对照、六类 I/O 注入分别说明。合成大文件只证明复制，不证明音频可解码。

## 如何维护？

新增失败先加最小复现；执行 python scripts/acceptance.py，审阅 moon info 的公开 API。改变既有调用语义需版本说明；纯修复用 patch，新增兼容 API 用 minor。0.2.0 保留原内存 API，但 CLI MD5 文本改为标准 hex。来源、素材许可和 AI 辅助持续记录。
