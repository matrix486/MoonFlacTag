# 维护者需要掌握的设计

标签编辑只重建 FLAC 开头元数据，原音频后缀按 bytes 保留。保留不是原音频有效性证明，不需要自写解码器。

Vorbis comment 长度/计数为小端，块头和 PICTURE 为大端。长度先用 unsigned 比较剩余空间再转 Int；严格 UTF-8 与编码前 surrogate 检查避免错误被替换字符掩盖。

Padding 的四字节块头不可省。保持偏移时剩余 1..3 bytes 也无法编码为合法块，必须报 NoSpace；不能在音频前塞裸字节。

Set 标签删除同名后追加，Add 追加，Remove 删除全部；ASCII 大小写无关。未知块保留，seektable 偏移相对音频帧，移动元数据不改变它。

0.3.0 的 edit_pictures 是有序选择：SetPicture 仅替换同类型，Add 追加，RemovePictureKind 删除同类型，ClearPictures 清空。--cover 采用选择性语义，旧 --cover-png 保留全替换行为。PNG IHDR/JPEG SOF 只用于元数据，不证明图片全部可解码。

metadata_prefix_length 返回下次精确需要的字节数，CLI 决定 read_more；格式判断仍在 MoonBit。缓冲扩容不修改已读取字节。plan 只输出新前缀；CLI 从旧边界复制音频，内存 rewrite 仍可用于已有完整 bytes 的调用方。

批量先扫描并固定文件列表/顺序，共享选项验证后逐个复用单文件处理。只在单个文件规划成功后创建输出父目录。输入输出树不得相互包含，扫描不跟随发现的符号链接。预览与保存是分别重新读取，不是冻结批次。

保存先写同目录私有临时文件，检查源变化并 fsync 后，以无覆盖硬链接发布完整目标。不能换成会覆盖既有目标的 rename。硬链接不支持则失败，不静默降级。强制退出可留临时文件，但不会以目标名暴露写到一半的文件；这与断电持久性、文件锁是不同保证。

错误编号由核心/CLI 或 Node I/O 提供，JSON 字段稳定并保留 error 文本别名。offset 不是统一全文件坐标。批量逐文件诊断记录 source/output。

测试数量为每后端 31（含 3 文档），循环中的 80 组/512 次分别陈述。FFmpeg 五组与 libsndfile 三组是独立编码路径；后者含约 98 KiB 复杂元数据，并以 soundfile/FFmpeg PCM 对照。性能记录含启动、仪器化和合成后缀，不把单次时间当普遍基准。

新增失败先最小复现，moon fmt / moon info 后跑 acceptance.py；审阅 API 和来源。核心运行无 FFmpeg/Python 依赖，这些仅是开发验证工具。

0.4.0 的可用性改进限定在 CLI：默认规划先 PreserveOffset，只在 NoSpace 时回退 Compact；库 API 默认不变。skip-existing 只跳过 lstat 识别的普通目标，不验证完成内容；report 在 stdout 输出完成后保存，失败不回滚音乐。独立运行包使用 release JS，不改写核心算法，构建时复制实际 core LICENSE；离线 npm 消费不执行生命周期脚本。
