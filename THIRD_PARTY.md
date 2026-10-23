# 来源、工具与 AI 辅助

格式依据：[RFC 9639 §8](https://www.rfc-editor.org/rfc/rfc9639.html)（FLAC 元数据、Vorbis comment、PICTURE）。实现独立编写，未复制或改名移植上游库。未包含规范大段原文。项目 MIT。

运行依赖为 MoonBit core；Node CLI 使用 Node.js 内置文件 I/O。FFmpeg/ffprobe 是独立开发验证工具，未链接或打包到本模块；Python 标准库用于素材、验证与归档消费脚本。PDF 生成工具不属于库依赖。

fixtures/tone.flac 是项目生成的 sine，cover.png 为项目生成色块，均随本项目 MIT 提供。测试里的合成 bytes 为原创结构 fixture。

AI 辅助用于调研、设计、代码、测试与文档。参赛者仍需亲自理解核心边界、端序、长度校验、重复标签及 padding 规划；用户已指定本项目发布身份为 matrix486；未提供的个人报名资料不猜填。原中性本地提交保留真实历史，本轮发布提交使用 matrix486。

0.2.0 的额外多声道/24 bit 素材同样由 FFmpeg lavfi sine 现场生成，仅在忽略目录保存。268439553 bytes 大文件使用原元数据及合成零后缀，仅测试 I/O；比对后删除。故障注入脚本仅覆盖验证进程的 Node fs 方法，不进入产品运行路径。

新发现的 Xcsa-ee/moonflac 仅作为竞争分析参考，未复制或链接其源码。CI 使用官方 MoonBit 发行归档；actions/checkout、setup-node、setup-python 为外部 CI 工具，不是库运行依赖。

0.3.0 验证额外使用 soundfile 0.13.1 / libsndfile 1.2.2（FLAC 编码与读取）及 numpy 1.26.4（生成数值信号/对照）。使用已安装开发环境，未将其二进制或源码打包到本模块。相关工具各自许可按其发行物执行；本库运行不依赖它们。

新语料为现场生成信号、独立 Python 编码的复杂元数据及 FFmpeg 生成 JPEG 色块。没有第三方录音；所有生成文件留在忽略目录并按脚本清理。512 次确定性突变来自本项目合成 fixture。PNG/JPEG 代码只读取格式头，未移植图片解码器。

0.4.0 独立运行包内的 JS 是本项目与 MoonBit core 经官方编译器生成的程序，运行只使用 Node 内置模块。包内附带本项目 MIT、MoonBit core 原 LICENSE 与本来源说明；不打包 Node、npm、MoonBit 工具链、Python 或媒体工具。npm 只用于本地离线安装消费验证，未发布到注册表。
