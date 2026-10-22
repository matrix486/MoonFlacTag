# 开发与维护

已验证 MoonBit 0.10.13+cbb11c36f（moon 0.1.20260915）、Node 24、Python 3.9+，集成需要 FFmpeg/ffprobe。第二编码/PCM oracle 使用 soundfile==0.13.1、numpy==1.26.4，仅开发使用，CI 已配置。

核心类型、纯格式与编辑逻辑放根包，cmd/main 负责 CLI 和宿主 I/O 桥。每个顶层声明用 ///|，公开类型由公开包拥有，接口经 moon info 生成。

针对实际失败增加最小复现；关键编码使用手工 golden 或独立 oracle。执行 moon fmt；moon info --target wasm-gc；审阅接口；python scripts/acceptance.py。同一入口覆盖所有本地门槛，CI 尚未在线运行。

文件保存测试要求环境允许同目录硬链接；在禁止该操作的沙箱内会失败，不应将测试改成绕过原子发布。验证仅使用项目内临时目录，本机普通运行环境完成后检查相应 JSON。

性能基线不设机器相关时间阈值，只断言读取量与结果正确，记录含启动时间和 maxRSS。兼容语料由两套编码路径现场生成，清楚区分合成数据和真实媒体格式。

不要手改 mbti、复制凭据/工具链/研究原件或把生成大文件纳入分发。新增素材说明来源。发布前另指定身份/owner/namespace；本轮只在本地保存。

命令行交付检查还需要 npm（随 Node 安装），使用 --offline、本地 prefix 和项目内临时缓存，不运行安装脚本。build_cli.py 生成只需 Node 24+ 的 zip/tgz；核心解析仍由 MoonBit 构建，已编译 JS 只进入本地独立运行包，库源码包不包含构建产物。
