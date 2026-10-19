# 三分钟本地演示 - 0.2.0

需要 MoonBit、Node.js，在项目根目录操作。mkdir demo-output（目录不存在时）。输出用新文件名，重复演示可换后缀。

0-30 秒：inspect 展示合成 sine 的 Original 标题与采样信息；说明本项目解决元数据编辑及无重编码保存，已有 FLAC 解码库可作为互补组件。

~~~powershell
moon run cmd/main --target js -- inspect fixtures/tone.flac
moon run cmd/main --target js -- plan fixtures/tone.flac --set=TITLE=MoonFlacTag --add=ARTIST=Guest
~~~

30-100 秒：plan 的 preview=true，展示 metadata_delta=0；保存后增加封面，再检查标签。

~~~powershell
moon run cmd/main --target js -- edit fixtures/tone.flac demo-output/demo-tagged.flac --set=TITLE=MoonFlacTag --add=ARTIST=Guest
moon run cmd/main --target js -- edit demo-output/demo-tagged.flac demo-output/demo-cover.flac --cover-png=fixtures/cover.png --compact
~~~

100-145 秒：展示 plan_metadata 与 examples/plan 的两后端相同输出；解释偏移预算不足和 1..3 字节余量为何返回 NoSpace；展示短写/磁盘故障无残缺输出的记录。CLI 只读取有界前缀并分块复制音频。

145-180 秒：展示 docs/test-evidence。原素材压缩音频 3158 bytes、PCM 22050 bytes 一致，另四组包含 24 bit / 六声道对照；大文件 268439553 bytes 是合成 I/O fixture，不冒充音频解码证明。

完整复现 python scripts/acceptance.py。参赛者应能说明根包与 Node I/O 边界，详见 maintainer-guide.md。
