# MoonFlacTag

纯 MoonBit FLAC 标签与封面编辑库，附 Node.js 命令行工具。支持单文件、目录批量预览/保存，以及 PNG/JPEG 封面管理；原压缩音频逐字节保留，无需重新编码。核心支持 Wasm-GC 和 JavaScript。

## 普通用户安装

从 [GitHub Release](https://github.com/matrix486/MoonFlacTag/releases/tag/v0.4.0) 下载并解压 `moonflactag-cli-0.4.0.zip`，Windows 用其中的 `moonflactag.cmd`。只需 Node.js 24+，不需要 MoonBit、Python、FFmpeg 或联网。还提供本地离线 npm 安装包。完整安装、批量恢复和问题处理见 [命令行手册](docs/cli-guide.md)。

开发者重建独立运行包：`python scripts/build_cli.py`。下文保留从源码启动的开发者入口。

## 单文件使用

需要 MoonBit 和 Node.js，在项目根目录运行：

~~~powershell
New-Item -ItemType Directory -Path demo-output -Force
moon run cmd/main --target js -- inspect fixtures/tone.flac
moon run cmd/main --target js -- plan fixtures/tone.flac --set=TITLE=Preview
moon run cmd/main --target js -- edit fixtures/tone.flac demo-output/tagged.flac --set=TITLE=MoonFlacTag --add=ARTIST=Guest
moon run cmd/main --target js -- edit fixtures/tone.flac demo-output/covered.flac --cover=fixtures/cover.png --compact
moon run cmd/main --target js -- extract-cover demo-output/covered.flac demo-output/extracted.png --index=0
~~~

输出必须是新文件，重复演示请换输出名。inspect 显示音频参数、标签、图片索引和类型；plan 显示编辑后信息、元数据差值和大小，不写文件。CLI 默认 --auto-padding 先尝试保持音频偏移，空间不足自动紧凑编码；--preserve-offset 才要求空间不足时返回 PADDING_NO_SPACE。库 API 默认策略仍保持偏移。--compact 允许移动音频，--padding=N 指定 0..16777215 字节 padding，最后一个 padding 选项生效。

标签支持 --set=KEY=VALUE、--add=KEY=VALUE、--remove=KEY。匹配忽略 ASCII 大小写，保留重复值；Set 替换全部同名值，Add 追加，Remove 删除全部。操作按顺序执行。

## 批量整理

将下面 album-in / album-out 换成自己的文件夹。输入输出树必须互不包含，输出目录可不存在。

~~~powershell
moon run cmd/main --target js -- batch plan album-in --recursive --set=ALBUM=Demo
moon run cmd/main --target js -- batch edit album-in album-out --recursive --set=ALBUM=Demo
~~~

- 默认仅当前目录，--recursive 才遍历子目录；扩展名 .flac 不区分大小写。
- 保留相对路径，按路径稳定排序；跳过扫描中发现的符号链接。
- 每个文件分别规划/保存，一个坏文件不阻断其余文件；已有输出不覆盖。
- stdout 是一份 JSON，含 total / succeeded / failed / skipped / skipped_symlinks 和逐文件 results。
- --skip-existing 仅 batch edit 可用，跳过已有普通输出文件，不比较内容；适合以相同选项重跑任务。改变标签应换新输出目录。
- --progress 在 stderr 输出逐文件进度 JSON 行；--report=NEW.json 保存 UTF-8 结果，包括部分失败结果；报告不覆盖。
- 全部成功退出 0，有失败退出 1；成功文件会保留，整批不是回滚事务。
- 预览与保存分别读取当前输入，预览不会冻结文件或创建输出目录。

最多 10000 个 FLAC 文件、20000 个扫描目录。共享选项错误在整批开始前返回错误；逐文件格式/保存错误记录在 results 中。批量和单文件使用相同标签、封面与 padding 选项。

## 封面操作

--cover=FILE 自动识别 PNG/JPEG 头，只替换选中类型，保留其他图片。默认类型 3（前封）；--picture-kind=N 设置后续封面操作类型，4 是后封，支持 0..20。

|选项/命令|作用|
|---|---|
|--cover=FILE|替换当前选中类型，保留其他类型|
|--append-cover=FILE|追加图片，不删除已有图片|
|--remove-picture-kind=N|删除指定类型的全部图片|
|--remove-pictures|清空图片|
|extract-cover INPUT OUTPUT --index=N|按 inspect 返回的索引原样导出，默认索引 0|
|--cover-png=FILE|兼容旧版：清空所有图片后放入一个 PNG 前封|

PNG/JPEG 头用于读取尺寸和色深，不解码像素或验证全部图片内容。导出不转换编码；若原 PICTURE 存的是 URI，则导出其原始 bytes，不访问链接。type 1/2 图标各最多一个，type 1 要求 32×32 PNG。

## 文件保存与错误

先在目标同目录创建私有临时文件，写完、检查源变化并 fsync 后，以不覆盖目标的硬链接操作原子发布完整文件。已有目标或竞态创建的目标保持原样。该方式要求文件系统和运行环境允许同目录硬链接；不支持时返回对应错误，不退回覆盖保存。

普通失败会尝试清理临时文件。强制退出时目标不会出现半成品，但可能留下 .moonflactag-*.tmp 私有临时文件，确认没有任务使用后可自行删除。原子可见性不等于断电持久性；源文件未锁定。

单文件操作失败输出 stderr JSON：code、message、operation、path、offset；旧 error 文本字段保留。自定义编号包括 INVALID_ARGUMENT、FLAC_INVALID、METADATA_LIMIT、PADDING_NO_SPACE、PICTURE_NOT_FOUND、PATH_OVERLAP、BATCH_LIMIT、SOURCE_CHANGED 等；文件 I/O 使用 Node 原始编号，例如 ENOENT、EEXIST、EPERM。offset 为相关解析器的位置，可能为空，不保证都是全文件偏移。完整约定见 [错误说明](docs/errors.md)。

## 库 API

正式模块名 `matrix486/moonflactag`，发布版本 0.4.0。安装：

~~~powershell
moon add matrix486/moonflactag@0.4.0
~~~

包配置使用 `import { "matrix486/moonflactag" @flac }`。公开文档：[Mooncakes 0.4.0](https://mooncakes.io/docs/matrix486/moonflactag@0.4.0)。本地开发仍可通过 moon.work 依赖。

- parse / Document.rewrite：完整 bytes 的内存接口。
- Document.plan / plan_metadata / RewritePlan：只编码新元数据前缀，宿主复制原音频后缀。
- metadata_prefix_length：增量读取精确需要的字节数，不预读音频。
- picture_from_image：PNG/JPEG 头转 Picture。
- edit_pictures：有序选择性封面编辑，不修改输入数组。

公开签名见 [pkg.generated.mbti](pkg.generated.mbti)，可执行示例见 [API.mbt.md](API.mbt.md)。跨后端示例：

~~~powershell
moon run examples/plan --target wasm-gc
moon run examples/plan --target js
~~~

## 一键验收

运行需要 MoonBit、Node 24、Python 3.9+、FFmpeg/ffprobe，兼容性测试另需 soundfile 0.13.1 / numpy 1.26.4（仅开发依赖）。

~~~powershell
python scripts/acceptance.py
~~~

两后端各 31 项测试（含 3 项文档测试）；另有 512 次确定性畸形输入突变、80 组编辑矩阵，循环次数不单列成测试数量。实际归档消费者各 2 项测试。完整流程覆盖：

- 目录批量预览、递归、部分失败、目标冲突及符号链接跳过。
- PNG/JPEG 识别、选择性替换、追加、删除和逐字节导出。
- 原有五组 FFmpeg 音频，加三组 libsndfile 8/16/24 bit 编码和约 98 KiB 复杂元数据；压缩后缀与 PCM 对照。
- 268439553 bytes 合成大文件、六类 I/O 注入、发布竞态和强制退出。
- 性能基线测量源读取量、含启动的耗时和 Node 峰值 RSS。64 MiB 合成样本 inspect 只读 8333 bytes 元数据，非通用速度承诺。

独立 CLI zip 在隔离路径运行并完成 npm tgz 离线安装/卸载；自动空间、批量进度/重跑和 UTF-8 报告也通过独立流程检查。记录在 docs/test-evidence。大型样本检查后删除，语料均为本地生成信号和独立元数据，不使用第三方录音。固定工具链 CI 结果见 [GitHub Actions](https://github.com/matrix486/MoonFlacTag/actions)。

## 边界与交付

累计元数据上限 16 MiB、4096 块，单块受 24 位长度约束；CLI 仅按需读取元数据，以 1 MiB 分块复制后缀。内存 API 的内存占用仍由调用方传入 bytes 决定。仅支持普通文件。

不验证音频帧 CRC / MD5，不解码图片，不支持 Ogg-FLAC / 前置 ID3。SEEKTABLE 检查顺序和占位符，但不核对目标帧；CUESHEET 内容保留为不透明 bytes。

0.4.0，MIT，GitHub owner 与发布账号为 matrix486。见 [验收复核](docs/acceptance-review.md)、[架构](docs/architecture.md)、[维护说明](CONTRIBUTING.md)、[来源](THIRD_PARTY.md)。公开仓库：[matrix486/MoonFlacTag](https://github.com/matrix486/MoonFlacTag)。发布状态与对应证据以 docs/release.md 为准；正式报名/审核仍需赛事方确认。
