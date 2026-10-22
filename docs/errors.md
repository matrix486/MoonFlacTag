# CLI 错误约定

单文件失败：退出 1，stdout 为空，stderr 输出单个 JSON。code、message、operation、path、offset 字段固定；error 是兼容旧脚本的 message 别名。path 或 offset 不适用时为空字符串或 null。

|编号|含义|
|---|---|
|INVALID_ARGUMENT|未知选项、数字越界、命令参数错误|
|FLAC_INVALID|元数据、图片头或类型不合要求|
|METADATA_LIMIT|块数、单块/累计长度超过限制|
|PADDING_NO_SPACE|无法按原偏移放入修改，包含剩余预算信息|
|IMAGE_LIMIT|图片文件超过单块可接受长度|
|PICTURE_NOT_FOUND|导出索引不存在|
|PATH_OVERLAP|批量输入输出树互相包含|
|BATCH_LIMIT|扫描文件或目录数量超过限制|
|INVALID_SOURCE|非普通文件或宿主无法精确表示的文件大小|
|TRUNCATED_INPUT|读取要求超出文件或读取中截断|
|SOURCE_CHANGED|保存前后观察到源大小/mtime/ctime 变化|
|WRITE_NO_PROGRESS|宿主写入返回零进展|
|INTERNAL_ERROR|未归类的异常，应该作为缺陷报告|

I/O 错误保留 Node 的平台错误编号，如 ENOENT / EACCES / EEXIST / EPERM / ENOSPC；平台可能返回不同底层编号，可结合 operation 分类。offset 是触发错误的相关解析器位置，不统一声明为全文件坐标。

batch 逐文件失败写入 stdout 的 results[].error，外层另有 input / output / relative；任一失败退出 1。共享选项或目录扫描失败在开始前按单文件错误格式输出。部分成功文件会保留，批量不是整体事务。

目标发布发生在完整临时文件写完之后。无权限建立硬链接或链接不受支持时返回错误并保留既有目标，不静默降级为覆盖写入。
