# 开发与维护

已验证 MoonBit 0.10.13+cbb11c36f（moon 0.1.20260915）、Node 24、Python 3.9+；集成测试需要 FFmpeg/ffprobe。

1. 使用清洁工作区，从 README 运行示例。
2. 根包放公共类型和纯核心，cmd/main 仅放 CLI 与 Node I/O。每个顶层声明用 ///|。
3. 为具体失败添加复现，保持正常输入和错误边界测试；关键编码需要独立 golden 或外部 oracle。
4. moon fmt；moon info --target wasm-gc；审阅接口变化。
5. python scripts/acceptance.py，覆盖核心、跨后端示例、媒体、文件失败及实际 zip 消费。

不要手改 pkg.generated.mbti，不将 research/、工具链、大型生成素材或私有台账纳入分发。素材更改需更新 fixtures/README.md。

CI 固定版本安装地址来自官方安装脚本，使用同一 acceptance.py。修改工具链后需实际验证并更新版本证据。正式仓库、作者与 registry namespace 在发布阶段指定；本项目当前只保留本地。
