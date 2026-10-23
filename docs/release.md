# 发布记录 — 0.4.0

首次公开日期：2026-10-23（Asia/Shanghai）。GitHub owner、上传账号、当前发布提交 author/committer 与 Mooncakes 登录者均为 matrix486。GitHub 已核对用户 ID 332895426；提交邮箱使用该账号的官方 noreply。此前中性本地开发提交保持原有时间和署名，首次公开时间不倒填。

源码仓库：https://github.com/matrix486/MoonFlacTag
模块：matrix486/moonflactag@0.4.0，MIT。
发布文档：https://mooncakes.io/docs/matrix486/moonflactag@0.4.0
独立 CLI 附件目标：https://github.com/matrix486/MoonFlacTag/releases/tag/v0.4.0

正式 namespace 迁移后完整本地验收通过；同一代码已通过 Ubuntu 24.04 线上 CI、Mooncakes 真实发布及公共 registry 独立安装。

- 发布包代码冻结提交：a391440eeb5b4942b65313003b35e6e06554c0ff。
- [代码冻结 CI](https://github.com/matrix486/MoonFlacTag/actions/runs/39918730181)：success，覆盖全部验收及接口检查。
- Mooncakes 0.4.0：服务端 200 OK；公开页面显示版本、MIT、matrix486 与本仓库。实际上传 67 文件。
- 注册表归档官方 SHA-256：8d1eb98f954d330bf5309cd253ec77ed1e3aca03b0d43c39ea46f182b3538bf0。
- registry 独立消费：公共下载确切 0.4.0，Wasm-GC / JS 各 2 测试通过，下载包 CLI inspect 通过。见 registry-consumption.json。
- 本机自动索引更新发生 Git 合并等待；官方索引已含确切版本，使用 moon add --no-update 读取该索引并实际下载包，没有本地源码替代。
- 发布后补充的消费脚本、证据和材料提交与包代码冻结提交区分。版本不可变，未重复发布。默认分支后续材料的 CI 见 [最新 main 运行](https://github.com/matrix486/MoonFlacTag/actions?query=branch%3Amain)。

能力与本地历史：0.1.0 首次实现；0.2.0 增加规划和分块复制；0.3.0 增加批量/选择性封面/原子发布及第二编码路径；0.4.0 提供 Node 独立包、自动空间、批量恢复/进度、UTF-8 报告。核心 Wasm-GC/JS 各 31 测试，独立库消费者各 2 测试；8 组媒体及故障验证不与测试计数混加。

库归档仅含源码、API、测试、必要 fixture、文档和复现脚本，排除 Git、工具链、缓存、研究抓取、私有台账、PDF 与临时消费工程。实际归档消费记录在 docs/test-evidence/package-consumption.json，该记录不嵌入其所描述的包。独立 CLI 是单独的产品构建附件，附项目与 MoonBit core LICENSE，不包含工具链或开发依赖。

目标保存要求硬链接；已有输出不覆盖。强制退出可遗留私有临时文件，不保证断电持久性。其他功能边界和完整操作见 README 及 cli-guide。

本次授权为代码与软件包发布，不包含正式报名、个人信息表单或赛事官方审核。
