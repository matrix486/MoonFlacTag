# 来源、工具与 AI 辅助

格式依据：[RFC 9639 §8](https://www.rfc-editor.org/rfc/rfc9639.html)（FLAC 元数据、Vorbis comment、PICTURE）。实现独立编写，未复制或改名移植上游库。未包含规范大段原文。项目 MIT。

运行依赖为 MoonBit core；Node CLI 使用 Node.js 内置文件 I/O。FFmpeg/ffprobe 是独立开发验证工具，未链接或打包到本模块；Python 标准库用于素材、验证与归档消费脚本。PDF 生成工具不属于库依赖。

fixtures/tone.flac 是项目生成的 sine，cover.png 为项目生成色块，均随本项目 MIT 提供。测试里的合成 bytes 为原创结构 fixture。

AI 辅助用于调研、设计、代码、测试与文档。参赛者仍需亲自理解核心边界、端序、长度校验、重复标签及 padding 规划；真实作者与报名信息待指定。中性本地 Git 身份不是参赛者身份。
