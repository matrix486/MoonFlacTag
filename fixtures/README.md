# 演示素材来源

tone.flac：本项目用 FFmpeg lavfi sine 生成的 440 Hz、0.25 秒、44100 Hz 单声道 16 bit 合成音频；非第三方录音。生成命令：

```
ffmpeg -v error -f lavfi -i sine=frequency=440:duration=0.25:sample_rate=44100 -c:a flac -metadata title=Original -metadata "artist=Synthetic source" tone.flac
```

cover.png：本项目用 Python 标准库 zlib/struct 生成的 1×1 RGB PNG 色块，无外部素材。

MoonBit 测试内的 synthetic-audio、PNG 等 bytes 仅是结构 fixture，不冒充可解码媒体；实际解码对照使用 tone.flac 和有效 cover.png。
