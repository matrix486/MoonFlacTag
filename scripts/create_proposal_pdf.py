"""Generate the one-page local proposal; requires reportlab and a CJK TTF."""
from pathlib import Path
import argparse
from reportlab.lib import colors
from reportlab.lib.enums import TA_LEFT
from reportlab.lib.styles import ParagraphStyle
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--font", default="C:/Windows/Fonts/simhei.ttf")
    args = parser.parse_args()
    pdfmetrics.registerFont(TTFont("CJK", args.font))
    dest = ROOT / "output/pdf/MoonFlacTag-proposal-0.1.0.pdf"
    dest.parent.mkdir(parents=True, exist_ok=True)
    navy = colors.HexColor("#142c46")
    teal = colors.HexColor("#087f8c")
    body = ParagraphStyle("body", fontName="CJK", fontSize=10.4, leading=16.6, textColor=navy, spaceAfter=8)
    small = ParagraphStyle("small", parent=body, fontSize=8.4, leading=13.3, textColor=colors.HexColor("#53667a"))
    heading = ParagraphStyle("heading", parent=body, fontSize=11.8, leading=18, textColor=teal, spaceBefore=9, spaceAfter=4)
    title = ParagraphStyle("title", parent=body, fontSize=27, leading=33, spaceAfter=6)
    subtitle = ParagraphStyle("subtitle", parent=body, fontSize=13.3, leading=20, textColor=teal, spaceAfter=13)
    story = [Paragraph("MoonFlacTag", title), Paragraph("FLAC 标签、封面与无损元数据编辑", subtitle), Paragraph("0.1.0  |  2026-10-17  |  十月赛本地申报草稿", small), Spacer(1, 8)]

    def section(label, text):
        story.append(Paragraph(label, heading))
        story.append(Paragraph(text, body))

    section("用户问题与生态新增", "面向音乐归档、媒体整理和上传工具：修改标题、作者或封面时，无需重新编码音频。相关 MoonBit rodio / FFmpeg 实现侧重播放与解码，本项目提供可嵌入 Wasm 的纯 MoonBit 元数据编辑库。读取 3048 条模块元数据并检查相关仓库，检索范围和竞品差异均有独立报告。")
    section("已交付能力", "STREAMINFO 读取；Vorbis 标签按大小写无关的键设置、追加、删除，并保留重复值；PICTURE 封面替换与删除；未知元数据块和原音频 bytes 保留；padding 支持保持偏移、指定大小与紧凑输出。根包为 MoonBit，Node CLI 的 JS FFI 仅承担文件和参数适配。")
    story.append(Paragraph("验证证据", heading))
    rows = [[Paragraph("检查范围", small), Paragraph("实际结果", small)], [Paragraph("Wasm-GC / JavaScript", body), Paragraph("各 16 项测试（含 1 文档测试）；格式、check、build 通过", body)], [Paragraph("真实媒体独立对照", body), Paragraph("FFmpeg / ffprobe 确认标签与封面；3158 bytes 压缩音频及 22050 bytes PCM 保持一致", body)], [Paragraph("实际归档消费", body), Paragraph("两后端各 1 项独立消费测试；解压后的 CLI 可运行", body)]]
    table = Table(rows, colWidths=[154, 357], hAlign="LEFT")
    table.setStyle(TableStyle([("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#e6f3f4")), ("VALIGN", (0, 0), (-1, -1), "TOP"), ("LEFTPADDING", (0, 0), (-1, -1), 9), ("RIGHTPADDING", (0, 0), (-1, -1), 9), ("TOPPADDING", (0, 0), (-1, -1), 6), ("BOTTOMPADDING", (0, 0), (-1, -1), 2), ("LINEBELOW", (0, 0), (-1, -1), 0.4, colors.HexColor("#d6e1e8"))]))
    story.append(table)
    section("工程边界与维护", "全文件内存处理；累计元数据 16 MiB / 4096 块，CLI 文件上限 256 MiB。不解码音频或图片，不校验音频帧 CRC / MD5；不支持 Ogg-FLAC 或前置 ID3。独立实现、MIT、合成音频与封面来源明确，AI 辅助范围已披露。后续以失败样例回归、API 版本化和宿主集成为主。")
    section("演示与提交状态", "三分钟演示：读取原文件 → 修改标签与封面 → 展示 padding 预算 → 对照原音频与解码结果。源码、文档、测试、素材与本地开发历史已保存。参赛者 / GitHub ID、公开仓库和 Mooncakes namespace 待指定；尚未公开发布、运行远端 CI 或正式报名。")
    story.append(Paragraph('技术依据：<link href="https://www.rfc-editor.org/rfc/rfc9639.html" color="#087f8c">RFC 9639 §8</link>；规则：<link href="https://github.com/moonbitlang/Hackathon2026/blob/main/src/App.tsx" color="#087f8c">官方十月赛页面源码</link>。详见项目内生态报告与验收复核。', small))

    def page(canvas, doc):
        canvas.setFillColor(teal)
        canvas.rect(42, 803, 36, 4, stroke=0, fill=1)
        canvas.setStrokeColor(colors.HexColor("#d6e1e8"))
        canvas.line(42, 38, 553, 38)
        canvas.setFont("CJK", 8)
        canvas.setFillColor(colors.HexColor("#53667a"))
        canvas.drawString(42, 24, "MoonFlacTag  /  Local proposal  /  2026-10-17")
        canvas.drawRightString(553, 24, str(doc.page))

    doc = SimpleDocTemplate(str(dest), pagesize=(595.28, 841.89), leftMargin=42, rightMargin=42, topMargin=50, bottomMargin=47, title="MoonFlacTag - Local proposal 0.1.0", author="MoonFlacTag contributors")
    doc.build(story, onFirstPage=page, onLaterPages=page)
    print(dest)


if __name__ == "__main__":
    main()
