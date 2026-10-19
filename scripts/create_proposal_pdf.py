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
    material_date = "2026-10-19"
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
    story = [Paragraph("MoonFlacTag", title), Paragraph("FLAC 标签、封面与无损元数据编辑", subtitle), Paragraph(f"{version}  |  {material_date}  |  十月赛本地申报草稿", small), Spacer(1, 8)]

    def section(label, text):
        story.append(Paragraph(label, heading))
        story.append(Paragraph(text, body))

    section("用户问题与生态新增", "面向音乐归档、媒体整理和上传工具：修改标题、作者或封面，无需重新编码音频。已有 MoonBit rodio / FFmpeg / moonflac 提供播放、解码或元数据读取，本项目独立贡献为编辑与写出。初次检索 3048 条模块元数据，本次针对 3114 条当前元数据刷新，并核对相关源码。")
    section("已交付能力", "重复 Vorbis 标签 set / add / remove；PICTURE 封面替换与删除；未知块和原音频 bytes 保留；padding 三策略；RewritePlan 元数据前缀规划与 CLI 只读预览。大文件以前缀有界读取和分块复制保存，短写重试，普通失败清理。格式与编辑为 MoonBit，JS FFI 只处理宿主文件 I/O。")
    story.append(Paragraph("验证证据", heading))
    rows = [[Paragraph("检查范围", small), Paragraph("实际结果", small)], [Paragraph("Wasm-GC / JavaScript", body), Paragraph("各 23 项测试（含 2 项文档测试）；格式、check、build；跨后端规划输出一致", body)], [Paragraph("真实媒体独立对照", body), Paragraph("五组音频，16 / 24 位、1 / 2 / 6 声道；FFmpeg / ffprobe 标签、封面、压缩音频与 PCM 对照通过", body)], [Paragraph("大文件与失败路径", body), Paragraph("268439553 bytes 合成后缀逐字节一致；短写、读写失败、fsync、源变化等六类注入通过", body)], [Paragraph("实际归档消费", body), Paragraph("两后端各 1 项独立消费测试；解压 CLI inspect / plan 成功", body)]]
    table = Table(rows, colWidths=[154, 357], hAlign="LEFT")
    table.setStyle(TableStyle([("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#e6f3f4")), ("VALIGN", (0, 0), (-1, -1), "TOP"), ("LEFTPADDING", (0, 0), (-1, -1), 9), ("RIGHTPADDING", (0, 0), (-1, -1), 9), ("TOPPADDING", (0, 0), (-1, -1), 6), ("BOTTOMPADDING", (0, 0), (-1, -1), 2), ("LINEBELOW", (0, 0), (-1, -1), 0.4, colors.HexColor("#d6e1e8"))]))
    story.append(table)
    section("工程边界与维护", "累计元数据 16 MiB / 4096 块，CLI 按 1 MiB 复制音频。检查源变化但不锁定文件，不承诺崩溃原子提交。不验证音频帧 CRC / MD5、不解码图片、不支持 Ogg-FLAC / 前置 ID3。MIT，合成素材来源清楚，AI 辅助范围已披露；维护说明、设计讲解和固定工具链 CI 配置已准备。")
    section("演示与提交状态", "三分钟演示：inspect → plan 预览 → 标签与封面编辑 → padding 预算与独立对照。统一复现入口：python scripts/acceptance.py。源码、文档、验证和真实本地历史就绪；参赛者 / GitHub ID、仓库和 Mooncakes namespace 待指定。尚未公开发布、在线运行 CI 或正式报名。")
    story.append(Paragraph('技术依据：<link href="https://www.rfc-editor.org/rfc/rfc9639.html" color="#087f8c">RFC 9639 §8</link>；规则：<link href="https://github.com/moonbitlang/Hackathon2026/blob/main/src/App.tsx" color="#087f8c">官方十月赛页面源码</link>。详见项目内生态报告与验收复核。', small))

    def page(canvas, doc):
        canvas.setFillColor(teal)
        canvas.rect(42, 803, 36, 4, stroke=0, fill=1)
        canvas.setStrokeColor(colors.HexColor("#d6e1e8"))
        canvas.line(42, 38, 553, 38)
        canvas.setFont("CJK", 8)
        canvas.setFillColor(colors.HexColor("#53667a"))
        canvas.drawString(42, 24, f"MoonFlacTag  /  Local proposal  /  {material_date}")
        canvas.drawRightString(553, 24, str(doc.page))

    doc = SimpleDocTemplate(str(dest), pagesize=(595.28, 841.89), leftMargin=42, rightMargin=42, topMargin=50, bottomMargin=47, title=f"MoonFlacTag - Local proposal {version}", author="MoonFlacTag contributors")
    doc.build(story, onFirstPage=page, onLaterPages=page)
    print(dest)


if __name__ == "__main__":
    main()
