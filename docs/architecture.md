# 架构与不变量

核心根包：FLAC 元数据解析、UTF-8/端序/预算检查、标签与 Picture 编辑、前缀规划、PNG/JPEG 头读取。CLI：参数、报告、批量任务与错误分类。host.mbt：普通文件描述符、按要求读取、目录遍历与文件提交的 Node I/O 桥。

metadata_prefix_length 只扫描签名和元数据块头：NeedMore(N) 表示精确需要至少 N bytes，Complete(offset) 表示链已结束。检查 16 MiB / 4096 块预算、首块类型和禁止类型，payload 语义仍交给 parse。CLI 从空前缀逐步 read_more，不再先读取 16 MiB 音频前缀。缓冲按需扩容，已返回视图中的字节保持不变。

parse 首块必须为 34 字节 STREAMINFO；STREAMINFO/VORBIS_COMMENT/SEEKTABLE/CUESHEET 各至多一块。padding 全零、APPLICATION 至少四字节、SEEKTABLE 为 18 字节单位、sample unsigned64 严格递增且占位符在末尾。保留未知块与非目标 payload，不解码音频。

Reader 中 Vorbis comment 长度与计数是小端，块头/PICTURE 是大端。u32 先比较剩余 bytes 再转 Int；文本严格 UTF-8。字段编码前验证 UTF-16 surrogate，避免编码器假设被破坏。

标签键匹配忽略 ASCII 大小写，Set 删除同名后追加，Add 保留已有，Remove 删除全部。vendor 原样保留，无标签时为 MoonFlacTag/0.3.0。

edit_pictures 对新数组按顺序操作：SetPicture 只替换同 kind，AddPicture 追加，RemovePictureKind 删除同 kind，ClearPictures 清空。其他图片原字节保留，图标唯一性仍检查。picture_from_image 读取 PNG IHDR / JPEG SOF，生成 MIME、尺寸、色深，不证明像素/CRC 完整。

Document.plan 只生成元数据，rewrite 在同一 plan 后追加原内存音频；plan_metadata 只接受精确前缀。音频边界来自元数据链末尾。padding 保持偏移预算为 original_offset - new_unpadded_size：0 完成、>=4 可放块头，负数或 1..3 返回 NoSpace。seektable 的偏移相对首音频帧，移动元数据无需调整它。

目录扫描真实解析输入/输出根，拒绝互相包含；迭代遍历、跳过发现的符号链接、按相对路径排序，最多 10000 文件/20000 目录。逐文件复用单文件同一选项与处理函数。共享选项先验证，逐文件失败保留诊断并继续。预览不冻结输入，保存时重新规划。

保存先固定源描述符，检查 size/mtimeNs/ctimeNs，然后在目标目录 wx 创建不可预测名临时文件，短写重试、分块复制、再次检查源变化并 fsync。以 fs.linkSync 无替换方式原子建立目标链接，再删除临时名字。竞态目标不会覆盖。普通失败尝试清理自身临时文件，defer 关闭源。此协议要求文件系统支持同目录硬链接；强制退出可能留私有临时文件，但未提交目标不存在，已提交目标完整。不宣称断电持久性或源文件锁定。

诊断由 MoonBit 将 FlacError / CliError 转成固定 JSON 字段；底层 I/O code 保留。批量错误内嵌源路径。Node 仅承担宿主操作，不解析标签语义。

测试层相互独立：手工 golden、确定性突变/性质矩阵、FFmpeg 对照、libsndfile 编码/PCM 对照、宿主故障与发布竞态、实际 zip 独立消费和仪器化性能记录。
