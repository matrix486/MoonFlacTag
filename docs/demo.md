# 三分钟本地演示

在项目根目录启动，需 MoonBit、Node.js。FFmpeg/ffprobe 仅对照环节需要。输出目录使用新文件名；重复演示前可选一个新的目录。

0-30 秒：展示 fixtures/tone.flac 的 Original 标题，说明改标签无需重编码。本项目是库和命令行工具，素材为合成 sine。

30-100 秒：

```powershell
moon run cmd/main --target js -- inspect fixtures/tone.flac
moon run cmd/main --target js -- edit fixtures/tone.flac demo-output/demo-tagged.flac --set=TITLE=MoonFlacTag --add=ARTIST=Guest
moon run cmd/main --target js -- edit demo-output/demo-tagged.flac demo-output/demo-cover.flac --cover-png=fixtures/cover.png --compact
```

对比 JSON 的 stream、comments、pictures 和 audio_offset。默认标签修改用现有 padding，封面演示显式选择 compact。

100-150 秒：对比 README 的十行 API；演示 `--remove=artist` 删除全部同名值；介绍 PreserveOffset 在空间不足或剩余 1..3 字节时返回 NoSpace，由使用者决定紧凑写出。

150-180 秒：展示 docs/test-evidence/local-verification.json 和验证脚本。真实结果：44100 Hz 单声道、11025 样本，原压缩音频 3158 bytes；编辑后压缩音频与 22050 bytes PCM 一致，提取 PNG 与原封面一致。

完整复现：`python scripts/verify.py`、`python scripts/verify_package.py`。错误例子与原文件不变检查已在脚本中自动执行。
