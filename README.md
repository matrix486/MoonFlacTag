# MoonFlacTag

纯 MoonBit FLAC 标签、封面与无损元数据编辑库。无需 libFLAC/FFmpeg 运行时依赖，核心可编译到 Wasm-GC 和 JavaScript，附 Node.js 命令行工具。

- 大小写无关的标签查询、设置、追加、删除，保留重复值和编码器 vendor。
- PICTURE 封面结构读写；保留未知块、APPLICATION、SEEKTABLE 和 CUESHEET 原始数据。
- 默认利用 padding 保持音频起始偏移；支持紧凑输出和指定 padding 大小。
- 原音频后缀逐字节复制；解析、编辑失败时输入不变。

## 快速运行

需要 MoonBit、Node.js；已验证工具链见 [release](docs/release.md)。运行目录为项目根目录。

```powershell
moon run cmd/main --target js -- inspect fixtures/tone.flac
moon run cmd/main --target js -- edit fixtures/tone.flac demo-output/tagged.flac --set=TITLE=MoonFlacTag --add=ARTIST=Guest
moon run cmd/main --target js -- edit fixtures/tone.flac demo-output/cover.flac --cover-png=fixtures/cover.png --compact
```

`demo-output` 目录需存在；也可选择自己的输出目录。输出文件必须是新路径。成功返回 0 并输出 JSON；输入/参数/预算/文件错误返回非零。多个 edit 选项按顺序处理；多次封面选项以最后一个为准。`--remove=KEY` 删除同名全部标签，`--remove-pictures` 删除全部封面。默认空间不足返回 `NoSpace`，可显式选择 `--compact` 允许音频偏移变化。

FLAC、PNG 都是本项目生成的合成演示素材，见 [fixtures 来源](fixtures/README.md)。通过 Node 直接运行构建结果：

```powershell
moon build --target js --deny-warn
node _build/js/debug/build/cmd/main/main.js inspect fixtures/tone.flac
```

## 库 API

本地模块名为 `local/moonflactag`；发布身份尚未指定。其他 MoonBit 模块可通过 `moon.work` 工作区依赖导入根包，实际分发消费验证见 `scripts/verify_package.py`。

```moonbit nocheck
let doc = @flac.parse(bytes)
let before = doc.stream_info()
let artists = doc.comments().values("artist")
let result = doc.rewrite(
  [Set("TITLE", "新标题"), Add("ARTIST", "Guest"), Remove("COMMENT")],
  padding=PreserveOffset,
)
// result.bytes 由调用方保存；doc 不变。
```

`pictures` 参数省略表示保留已有封面，`pictures=[]` 删除全部。`Padding::Exact(n)` 添加一个 n 字节 padding 块（即使 n=0，也有四字节头）；`Compact` 删除所有 padding；`PreserveOffset` 用剩余预算补 padding，剩余 1..3 字节无法容纳块头时也返回 `NoSpace`。

可执行示例见 [API.mbt.md](API.mbt.md)，完整签名见 [pkg.generated.mbti](pkg.generated.mbti)，结构和保证见 [architecture](docs/architecture.md)。

## 验证

```powershell
python scripts/verify.py
python scripts/verify_package.py
```

第一条执行格式、两后端检查/测试/构建、CLI 错误与媒体对照；媒体集成需要 FFmpeg/ffprobe，仅开发验证使用。第二条调用 `moon package`，检查真实归档，解压后从独立模块消费公开 API。结果保存在 `docs/test-evidence/`；原始输出进入忽略目录。

## 范围

处理 native FLAC 的元数据，整个文件驻留内存。核心累计元数据最多 16 MiB、4096 块，单块受 24 位长度约束；CLI 输入文件最多 256 MiB。核心不执行文件 I/O，不校验音频帧、CRC 或 MD5，不解码图片，不请求外部封面 URI。CUESHEET/SEEKTABLE 的内部语义不在验证范围（SEEKTABLE 只检查长度为 18 的倍数）。不支持 Ogg-FLAC 或前置 ID3。

本地版本 0.1.0，MIT；来源和 AI 辅助说明见 [THIRD_PARTY](THIRD_PARTY.md)。本次仅本地完成；公开仓库、Mooncakes、正式申报信息待指定。
