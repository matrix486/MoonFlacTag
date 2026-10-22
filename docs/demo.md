# 三分钟本地演示 - 0.3.0

需要 MoonBit/Node，在项目根目录新建 demo-output。输出名需未占用。

0-35 秒：inspect 展示原音频、标签与图片；plan 更改 TITLE，显示无写入预览。

~~~powershell
moon run cmd/main --target js -- inspect fixtures/tone.flac
moon run cmd/main --target js -- plan fixtures/tone.flac --set=TITLE=MoonFlacTag
~~~

35-95 秒：保存标签与 PNG 前封，再原样导出。

~~~powershell
moon run cmd/main --target js -- edit fixtures/tone.flac demo-output/demo-covered.flac --set=TITLE=MoonFlacTag --cover=fixtures/cover.png --compact
moon run cmd/main --target js -- extract-cover demo-output/demo-covered.flac demo-output/demo-cover.png --index=0
~~~

说明 --cover 只替换默认前封，--picture-kind=4 可操作后封，--append-cover 追加，JPEG 也可导入。展示 product-workflows.json 的实际前/后封保留和逐字节导出对照。

95-140 秒：以自己准备的 album-in（两首正常、一首损坏、一个嵌套文件）演示 batch plan，再向不重叠的新 album-out 执行 batch edit --recursive --set=ALBUM=Demo，观察逐文件结果与部分失败退出。预览不冻结输入，单个失败不阻断整批。

140-180 秒：展示 31 项双后端测试、FFmpeg 与 libsndfile 两种编码路径、512 次突变和复杂标签对照；显示 64 MiB 文件 inspect 只读 8333 bytes。说明完整临时文件再发布目标的协议与强制退出测试。

一键复现 python scripts/acceptance.py；统计与素材边界见 acceptance-review.md。
