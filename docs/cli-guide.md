# MoonFlacTag 命令行使用手册

本地版本 0.4.0。独立运行包只需要 Node.js 24 或更新版本，不需要 MoonBit、Python、FFmpeg 或联网。它编辑 FLAC 元数据并逐字节保留压缩音频，不转换音频编码。

## 安装与启动

开发者在源码目录运行 `python scripts/build_cli.py`，生成 `release-local/moonflactag-cli-0.4.0.zip` 和 `release-local/moonflactag-local-cli-0.4.0.tgz`，不会上传。

普通用户解压 zip 到自己选择的目录，Windows 用包内的 `moonflactag.cmd`。以下命令假定当前位于解压目录：

~~~powershell
.\moonflactag.cmd --version
.\moonflactag.cmd --help
.\moonflactag.cmd inspect .\examples\tone.flac
~~~

也可从任意目录通过完整路径调用 `moonflactag.cmd`；输入、输出、图片和报告的相对路径均相对于你当前的工作目录，不是安装目录。跨平台入口是 `node /path/to/package/bin/moonflactag.cjs`；Linux/macOS 也可用 `sh /path/to/package/moonflactag`。仅 Windows 本机已实测，其他系统由 CI 配置待验证。

如果已经使用 npm，可以只在选定目录离线安装，以下不修改系统全局安装：

~~~powershell
npm install --prefix .\my-tools --offline --ignore-scripts --no-audit --no-fund .\moonflactag-local-cli-0.4.0.tgz
.\my-tools\node_modules\.bin\moonflactag.cmd --help
~~~

Windows 上 npm 自动生成的 `.cmd` 入口对安装路径中的 `&` 等命令符号有兼容问题，npm 安装目录请避免这些符号；中文和空格可用。独立 zip 的自带入口支持含 `&` 的目录，也可直接用 node 调用已安装包的 `bin/moonflactag.cjs`。

更新时解压到新的版本目录，验证后换用新入口；旧目录可保留。卸载时删除自己解压的独立包目录，或执行 `npm uninstall --prefix .\my-tools moonflactag-local-cli --ignore-scripts --no-audit --no-fund`。音乐和报告始终留在调用命令时指定的位置。

## 单文件完整流程

~~~powershell
.\moonflactag.cmd inspect .\examples\tone.flac
.\moonflactag.cmd plan .\examples\tone.flac "--set=TITLE=我的曲目" "--add=ARTIST=另一位艺术家" --report=reports/preview.json
.\moonflactag.cmd edit .\examples\tone.flac output/album/01.flac "--set=TITLE=我的曲目" "--add=ARTIST=另一位艺术家" --cover=examples/cover.png
.\moonflactag.cmd inspect output/album/01.flac
.\moonflactag.cmd extract-cover output/album/01.flac output/art/front.png --index=0
~~~

查看和预览不会修改音乐文件。保存和导出自动创建输出父目录，输出文件必须是新路径。用完整的 `"--set=KEY=VALUE"` 引号包住含空格的参数；所有选项采用 `--option=value`，并在输入输出位置参数之后使用。

标签名忽略 ASCII 大小写：`--set=ARTIST=某人` 替换该名称的全部值，`--add=ARTIST=某人` 追加，`--remove=ARTIST` 删除该名称的全部值。空值允许，标签值内的等号保留。多个操作按给定顺序执行。

默认 `--auto-padding` 尽量保持原音频偏移，空间不足自动紧凑编码元数据；压缩音频 bytes 不变。`--preserve-offset` 强制保留偏移，空间不足报 PADDING_NO_SPACE；`--compact` 去除 padding；`--padding=N` 指定精确 padding，N 为 0..16777215。最后一个空间选项生效。

## 批量专辑整理与重跑

将路径替换为自己的输入输出目录，两个目录树必须互不包含：

~~~powershell
.\moonflactag.cmd batch plan "D:\Music\待整理" --recursive "--set=ALBUM=示例专辑" --report=reports/album-preview.json
.\moonflactag.cmd batch edit "D:\Music\待整理" "D:\Music\整理结果" --recursive "--set=ALBUM=示例专辑" --progress --report=reports/album-run1.json
.\moonflactag.cmd batch edit "D:\Music\待整理" "D:\Music\整理结果" --recursive "--set=ALBUM=示例专辑" --skip-existing --progress --report=reports/album-run2.json
~~~

默认只扫描当前目录，加 `--recursive` 扫描子目录；保留相对路径和文件名，扩展名大小写不限，不复制非 FLAC 文件。封面、标签和空间选项作用于本批所有输入；逐曲不同标题或曲号用单文件 edit 分别设置。扫描到的符号链接跳过。

每个文件独立保存，一个失败会继续处理其余文件。结果 JSON 的 `results` 记录每条路径、状态和错误；`total = succeeded + failed + skipped`。`--progress` 在 stderr 输出逐文件进度 JSON 行，stdout 始终只输出一份结果 JSON。存在失败退出 1，否则退出 0；整批操作不回滚成功文件。

`--skip-existing` 只用于 batch edit：已有普通输出文件直接跳过，不读取/比较其内容，也不证明它已经应用当前标签。适用于使用相同选项恢复中断任务；如果改变了标签或封面，应选择新输出目录。已有目录或符号链接仍报错，不跳过或覆盖。若输出文件损坏，可检查后将它移到其他位置，再重跑相同任务。

每次使用新的报告名。`--report=NEW.json` 在命令完成后以 UTF-8 保存与 stdout 相同的 JSON，部分失败的批量结果也会保存；报告不覆盖已有文件。命令开始前发现已有报告会直接拒绝执行。若报告保存后来失败，音乐文件已经完成的写入会保留，stdout 仍包含完整结果、stderr 给出报告错误，退出 1。选项/扫描等导致任务未开始的错误只输出 stderr，不创建结果报告。

## 封面

`--cover=FILE` 识别 PNG/JPEG 头，替换当前类型的全部图片，保留其他类型。默认类型 3 为前封；`--picture-kind=4 --cover=back.jpg` 替换后封。`--append-cover=FILE` 追加，`--remove-picture-kind=N` 删除选定类型，`--remove-pictures` 清空。类型选项只影响后续图片操作。旧 `--cover-png=FILE` 会清空全部图片再添加 PNG 前封。

inspect 的 pictures 给出图片索引；`extract-cover INPUT OUTPUT --index=N` 按索引原样导出，默认 0，不转换图片编码。URI 类型仅导出原始 URI bytes，不访问网络。

## 常见问题

|情况|处理|
|---|---|
|找不到 node|安装 Node.js 24 或更新版本，并在新终端确认 `node --version`|
|EEXIST|输出/报告已存在，换一个名称；批量恢复可用 --skip-existing|
|PADDING_NO_SPACE|改用 --auto-padding 或 --compact，允许改变音频位置|
|ENOENT|检查当前目录和输入路径；含空格时给整个路径加引号|
|EPERM / ENOTSUP / EOPNOTSUPP|检查写权限和目标文件系统是否支持硬链接；例如不支持的移动盘可先写到本地 NTFS，再复制已完成文件|
|SOURCE_CHANGED|保存时源发生变化，停止其他编辑器后用新输出名重试|
|FLAC_INVALID / TRUNCATED_INPUT|输入不完整或不是受支持的原生 FLAC，保留源并检查文件|
|批量 failed 大于 0|查看 results 中的 relative 和 error，修复该项后重跑；已成功的输出保留|

目标以同目录临时文件写完、同步后，通过硬链接原子发布，已有目标不覆盖。强制退出可能留下 `.moonflactag-*.tmp` 私有临时文件；确认无任务使用后再清理。此机制不承诺断电持久性，源未锁定。

当前支持原生 FLAC 普通文件，元数据上限 16 MiB / 4096 块。图片头识别不解码像素，音频保留不代表校验了每帧 CRC/MD5；不支持 Ogg-FLAC、前置 ID3 或就地覆盖。独立包不包含音频解码器，也不需要解码器才能编辑。
