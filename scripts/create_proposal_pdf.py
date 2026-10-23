"""Generate the one-page local proposal; requires reportlab and a CJK TTF."""
from pathlib import Path
import argparse
import re
from reportlab.lib import colors
from reportlab.lib.styles import ParagraphStyle
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--font", default="C:/Windows/Fonts/simhei.ttf")
    args = parser.parse_args()
    version = re.search(r'^version\s*=\s*"([^"]+)"', (ROOT / "moon.mod").read_text(encoding="utf-8"), re.M)[1]
    material_date = "2026-10-23"
    pdfmetrics.registerFont(TTFont("CJK", args.font))
    dest = ROOT / f"output/pdf/MoonFlacTag-proposal-{version}.pdf"
    dest.parent.mkdir(parents=True, exist_ok=True)
    navy = colors.HexColor("#142c46")
    teal = colors.HexColor("#087f8c")
    body = ParagraphStyle("body", fontName="CJK", fontSize=10.4, leading=16.6, textColor=navy, spaceAfter=8, wordWrap="CJK")
    small = ParagraphStyle("small", parent=body, fontSize=8.4, leading=13.3, textColor=colors.HexColor("#53667a"))
    heading = ParagraphStyle("heading", parent=body, fontSize=11.8, leading=18, textColor=teal, spaceBefore=9, spaceAfter=4)
    title = ParagraphStyle("title", parent=body, fontSize=27, leading=33, spaceAfter=6)
    subtitle = ParagraphStyle("subtitle", parent=body, fontSize=13.3, leading=20, textColor=teal, spaceAfter=13)
    story = [Paragraph("MoonFlacTag", title), Paragraph("FLAC 标签、封面与无损元数据编辑", subtitle), Paragraph(f"{version}  |  {material_date}  |  十月赛项目说明 · matrix486", small), Spacer(1, 8)]

    def section(label, text):
        story.append(Paragraph(label, heading))
        story.append(Paragraph(text, body))

    section("用户问题与生态新增", "面向音乐归档、媒体整理和上传工具：修改标题、作者或封面，无需重新编码音频。已有 MoonBit rodio / FFmpeg / moonflac 提供播放、解码或元数据读取，本项目独立贡献为编辑与写出。选题及生态去重依据保存在项目报告中，检索日期和范围可追溯。")
    section("已交付能力", "重复标签 set / add / remove；PNG / JPEG 图片头识别、按类型替换及追加封面、原始图片导出；目录批量预览及编辑、逐文件错误报告。未知块与压缩音频保留，padding 三策略。按需读取元数据，原子发布且拒绝覆盖。新增只需 Node 的独立包和离线安装、自动空间、批量恢复/进度与 UTF-8 报告。格式和编辑逻辑为 MoonBit。")
    story.append(Paragraph("验证证据", heading))
    rows = [[Paragraph("检查范围", small), Paragraph("实际结果", small)], [Paragraph("Wasm-GC / JavaScript", body), Paragraph("各 31 项测试（含 3 项文档测试）；512 次确定性变异；格式、check、build 通过", body)], [Paragraph("真实媒体独立对照", body), Paragraph("FFmpeg 五组与 libsndfile 三组编码；8 / 16 / 24 位、复杂标签、压缩音频与 PCM 对照通过", body)], [Paragraph("保存安全与读取成本", body), Paragraph("并发目标、链接失败、强制退出验证通过；约 64 MiB 合成文件 inspect 只读 8333 字节", body)], [Paragraph("实际归档消费", body), Paragraph("公共 registry 确切 0.4.0 两后端各 2 项测试、下载 CLI 通过；zip/tgz 安装运行通过", body)]]
    table = Table(rows, colWidths=[154, 357], hAlign="LEFT")
    table.setStyle(TableStyle([("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#e6f3f4")), ("VALIGN", (0, 0), (-1, -1), "TOP"), ("LEFTPADDING", (0, 0), (-1, -1), 9), ("RIGHTPADDING", (0, 0), (-1, -1), 9), ("TOPPADDING", (0, 0), (-1, -1), 6), ("BOTTOMPADDING", (0, 0), (-1, -1), 2), ("LINEBELOW", (0, 0), (-1, -1), 0.4, colors.HexColor("#d6e1e8"))]))
    story.append(table)
    section("工程边界与维护", "累计元数据 16 MiB / 4096 块；音频按 1 MiB 复制。目标文件系统须支持硬链接；强制退出可遗留私有临时文件，不保证断电持久性。检测源变化但不锁定；不解码图片或音频帧，不支持 Ogg-FLAC / 前置 ID3。MIT，素材来源、性能测量方法、维护说明与固定工具链 CI 配置齐备。")
    section("演示与提交状态", "三分钟演示：独立包启动 → plan → 标签封面编辑/导出 → batch edit / 恢复与报告。统一复现入口：python scripts/acceptance.py。GitHub：matrix486/MoonFlacTag；Mooncakes：matrix486/moonflactag@0.4.0。源码已公开，线上 CI 与公共 registry 独立安装验证通过。正式报名和赛事审核未执行。")
    story.append(Paragraph('技术依据：<link href="https://www.rfc-editor.org/rfc/rfc9639.html" color="#087f8c">RFC 9639 §8</link>；规则：<link href="https://github.com/moonbitlang/Hackathon2026/blob/main/src/App.tsx" color="#087f8c">官方十月赛页面源码</link>。详见项目内生态报告与验收复核。', small))

    def page(canvas, doc):
        canvas.setFillColor(teal)
        canvas.rect(42, 803, 36, 4, stroke=0, fill=1)
        canvas.setStrokeColor(colors.HexColor("#d6e1e8"))
        canvas.line(42, 38, 553, 38)
        canvas.setFont("CJK", 8)
        canvas.setFillColor(colors.HexColor("#53667a"))
        canvas.drawString(42, 24, f"MoonFlacTag  /  matrix486  /  {material_date}")
        canvas.drawRightString(553, 24, str(doc.page))

    doc = SimpleDocTemplate(str(dest), pagesize=(595.28, 841.89), leftMargin=42, rightMargin=42, topMargin=50, bottomMargin=47, title=f"MoonFlacTag - Project proposal {version}", author="matrix486")
    doc.build(story, onFirstPage=page, onLaterPages=page)
    print(dest)


if __name__ == "__main__":
    main()
