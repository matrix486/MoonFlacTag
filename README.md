# MoonFlacTag

纯 MoonBit FLAC 标签、封面与无损元数据编辑库。核心支持 Wasm-GC 和 JavaScript，Node.js CLI 以分块方式保存大文件。无需 libFLAC / FFmpeg 运行时依赖。

- 大小写无关的标签查询、设置、追加、删除，保留重复值和 vendor。
- PICTURE 封面结构读写，保留非目标元数据与原压缩音频 bytes。
- padding 保持偏移、紧凑输出和指定大小三种策略。
- RewritePlan 只含元数据前缀，可供外部流式宿主复用。
- plan 命令预览标签、元数据差值、新旧偏移和预计大小，不写文件。

## 快速运行

需要 MoonBit 和 Node.js，运行目录为项目根目录。第一次使用时创建自己的输出目录：

~~~powershell
mkdir demo-output
moon run cmd/main --target js -- inspect fixtures/tone.flac
moon run cmd/main --target js -- plan fixtures/tone.flac --set=TITLE=Preview
moon run cmd/main --target js -- edit fixtures/tone.flac demo-output/tagged.flac --set=TITLE=MoonFlacTag --add=ARTIST=Guest
moon run cmd/main --target js -- edit fixtures/tone.flac demo-output/cover.flac --cover-png=fixtures/cover.png --compact
~~~

输出路径必须是新文件；成功返回 0、输出 JSON，失败返回非零、stderr 输出 JSON error。多个标签操作按顺序处理。--remove=KEY 删除全部同名标签，--remove-pictures 删除全部封面。--cover-png=FILE 替换封面，检查 PNG 签名，不解码图片。重复封面选项以最后一个为准。

默认利用现有 padding 保持音频偏移。预算不足返回 NoSpace，调用方可选择 --compact；--padding=N 指定 0..16777215 字节 padding，这些选项按最后一个生效。--help / --version 提供入口说明。

CLI JSON 的 stream.md5 为 STREAMINFO 原始 MD5 的 32 个小写十六进制字符，本库不重新计算该值。total_samples 用十进制字符串，文件大小为宿主安全整数。

直接运行构建结果：

~~~powershell
moon build --target js --deny-warn
node _build/js/debug/build/cmd/main/main.js inspect fixtures/tone.flac
~~~

## 库 API

本地模块名 local/moonflactag，发布身份待指定。通过 moon.work 工作区依赖导入；实际消费方式见 scripts/verify_package.py。

~~~moonbit nocheck
let doc = @flac.parse(bytes)
let result = doc.rewrite(
  [Set("TITLE", "新标题"), Add("ARTIST", "Guest"), Remove("COMMENT")],
  padding=PreserveOffset,
)
~~~

pictures 参数省略表示保留，pictures=[] 删除全部。Exact(n) 添加 n 字节 padding（含另计四字节块头），Compact 删除 padding，PreserveOffset 用原预算补齐；剩余 1..3 字节无法容纳块头也返回 NoSpace。

流式宿主调用 plan_metadata(prefix, edits, ...)，prefix 必须精确结束于最后元数据块。写入 plan.metadata 后，从原文件 plan.old_audio_offset 处复制音频后缀。已有 Document 可用 doc.plan(...)；rewrite 留给需要完整内存输出的调用方。

~~~powershell
moon run examples/plan --target wasm-gc
moon run examples/plan --target js
~~~

公开签名见 [pkg.generated.mbti](pkg.generated.mbti)，可执行文档见 [API.mbt.md](API.mbt.md)，结构见 [architecture](docs/architecture.md)。

## 一键验收

~~~powershell
python scripts/acceptance.py
~~~

需要 Python 3.9+、FFmpeg/ffprobe，仅用于开发验证。入口执行：

- 格式、双后端 check / test / build；两后端各 23 项测试，含 2 项文档测试。
- 两后端示例输出逐字节一致。
- FFmpeg / ffprobe 的标签、封面、压缩音频及 PCM 对照。
- 四组额外媒体覆盖 22050/48000/96000 Hz、1/2/6 声道、16/24 位，PCM 以 s32le 保留精度。
- 超过旧 256 MiB 上限的大文件后缀对照，以及短写、读写失败、同步失败、源变化注入。
- 实际 zip 解压后独立消费，两后端各 1 项测试，解压 CLI 的 inspect/plan 可运行。

结果在 docs/test-evidence/，大型临时素材在检查后删除。可分别运行 verify.py、verify_cli.py、verify_media_matrix.py、verify_package.py。CI 配置位于 .github/workflows/ci.yml，使用相同入口和固定 MoonBit 版本；尚未在线运行。

## 资源与文件保证

核心累计元数据上限 16 MiB、4096 块，单块受 24 位长度约束。CLI 最多读 16 MiB 前缀，按 1 MiB 分块复制后缀，无 256 MiB 整文件上限；输入必须是普通文件，大小能由宿主安全整数精确表示。parse/rewrite 内存 API 仍处理调用方提供的 bytes；plan_metadata 适用于有界前缀。

独占创建新输出，短写重试，普通读写/同步错误时清理本次文件。用已打开的描述符复制，并检查源大小、mtime、ctime 变化。源文件未锁定，不承诺断电或进程被强制终止时的原子提交。

不校验音频帧、CRC 或 MD5，不解码图片、不获取封面 URI。SEEKTABLE 检查长度、递增样本和末尾占位符，不核对目标帧；CUESHEET 内容保持不透明，拒绝重复块。不支持 Ogg-FLAC / 前置 ID3。

0.2.0，MIT。素材见 [fixtures 来源](fixtures/README.md)，参考与 AI 辅助见 [THIRD_PARTY](THIRD_PARTY.md)，维护入口见 [CONTRIBUTING](CONTRIBUTING.md)。本地验收结论见 [复核报告](docs/acceptance-review.md)。公开仓库、Mooncakes 和正式申报信息待指定。
