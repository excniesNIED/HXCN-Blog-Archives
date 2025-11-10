# 更换SIM卡前必看：如何使用ADB导出并筛选指定SIM卡的全部短信

## 前情提要

最近，主包的流量卡的优惠套餐即将到期，主包打算更换新的手机卡。这张卡的手机号已经绑定了众多账号，而主包又不清楚这个号码究竟绑定了多少账号。

主包的华为手机的“信息”应用不支持按SIM卡筛选信息。主包先后尝试了SMS Tools、DekuSMS、SmsForwarder等多款短信管理应用。结果却令人失望，有的应用早已停止维护，无法正常运行；有的则根本不支持导入手机中已存在的历史短信，只能处理新接收的信息。由于华为手机的系统限制，限制禁止普通用户获取短信数据库路径，也无法通过第三方程序直接访问 `/data/data/com.android.providers.telephony/databases/mmssms.db`。由于手机未root，这条路径几乎被完全封锁。

在碰壁多次后，主包意识到可以一种更底层的、独立于应用之外的解决方案，也就是 **ADB（Android Debug Bridge）**。ADB是一个功能强大的命令行工具，它允许开发者直接与安卓设备进行深度通信和控制。对于主包的需求而言，它最关键的功能就是能够访问系统底层的内容提供器（Content Provider），其中就包括存储短信的数据库。

## 导出短信记录

在进行操作之前，需要先在手机的系统设置中打开“开发者选项”，并启用“USB调试”功能。这是允许电脑通过ADB与手机通信的基础。准备工作就绪后，主包将手机连接到电脑，下载安装 ADB 后，在终端输入：

```
./adb devices
```

提示设备 Conneted，证明 ADB 连接成功。

在命令行中执行：

```bash
adb shell content query --uri content://sms/
```

这条指令会直接输出短信数据库中的全部记录，包含发送者号码、时间戳、短信内容、所属SIM卡等关键信息。若要进一步区分通话记录、日历或通讯录，也可以使用类似语句，只需替换URI即可。

例如：

```bash
adb shell content query --uri content://call_log/calls
adb shell content query --uri content://contacts/phones/
```

然而，ADB 输出的短信内容是**结构化文本格式**，每条记录以“key=value”存储，多条记录之间没有标准分隔符。直接查看几乎无法阅读，也难以筛选出某一张卡的短信。因此，主包将输出结果重定向保存为文本文件：

```bash
adb shell content query --uri content://sms/ > all_sms.txt
```

这一步得到了一个包含数千行记录的文件。

## 文本结构化

`all_sms.txt` 文件表面上是普通文本，但它包含复杂的键值对结构，例如：

```
Row: 1 _id=2982, thread_id=1402, address=106819388006257049, person=0, date=1761720271713, date_sent=1761720269000, protocol=0, read=1, status=-1, type=1, reply_path_present=0, subject=NULL, body=【滴滴出行】验证码：(114514)，您正在使用短信验证码登录功能，2分钟内有效。转发可能导致帐号被盗，请勿泄露给他人   , service_center=+8615654161, locked=0, sub_id=1, network_type=13, error_code=0, creator=com.android.mms, seen=1, si_id=NULL, mid=NULL, created=NULL, mtype=0, privacy_mode=0, group_id=7627, addr_body=0,, time_body=0,, risk_url_body=, is_secret=1, resent_im=0, hw_is_satellite=0
```

每一行都由多个`key=value`格式的字段组成，字段之间用逗号隔开。例如，`address=`后面是对方号码，`body=`是短信正文，`date=`是时间戳。

直接用 Excel 打开毫无意义。为了分析这些字段，主包编写了一个 **Python 转换脚本**，核心思路是：
 利用正则表达式识别“逗号后紧跟key=”的模式，将每行分割为字段字典，再统一写入CSV文件。

该脚本会自动处理短信内容中的逗号、等号等特殊字符，防止误分割。每条记录都会被转换成一行数据，字段列包括 `_id`、`address`、`body`、`sub_id` 等。

```bash
import csv
import re
import os

def convert_sms_to_csv(input_filepath, output_filepath):
    """
    将通过 adb 命令导出的短信 txt 文件转换为 CSV 格式。

    Args:
        input_filepath (str): 输入的 txt 文件路径 (all_sms.txt)。
        output_filepath (str): 输出的 csv 文件路径。
    """
    # 正则表达式：用于按逗号分割，但前提是这个逗号后面紧跟着一个 "键=值" 的模式。
    # \s* 匹配0个或多个空格
    # (?=\w+=) 是一个正向先行断言，它会查找 "单词= " 的模式，但不会消耗这些字符。
    # 这确保我们只在字段之间进行分割，而不会分割字段内部的内容。
    # 例如，对于 "body=..., service_center=..."，它会在 ", " 处分割。
    pattern = re.compile(r',\s*(?=\w+=)')

    all_rows_data = []
    
    # 检查输入文件是否存在
    if not os.path.exists(input_filepath):
        print(f"错误：输入文件 '{input_filepath}' 不存在。")
        return

    print(f"正在读取文件: {input_filepath}...")
    
    with open(input_filepath, 'r', encoding='utf-8') as f:
        for i, line in enumerate(f):
            # 去除行首的 "Row: x " 部分和行尾的空白字符
            # 找到第一个 " _id=" 的位置，从那里开始切片，更具鲁棒性
            start_index = line.find('_id=')
            if start_index == -1:
                print(f"警告：第 {i+1} 行格式不正确，已跳过: {line.strip()}")
                continue
            
            content = line[start_index:].strip()

            # 使用正则表达式分割成 "key=value" 块
            fields = pattern.split(content)
            
            row_dict = {}
            for field in fields:
                # 按第一个等号分割，防止 value 中也包含等号
                parts = field.split('=', 1)
                if len(parts) == 2:
                    key, value = parts
                    # 有些值可能是 NULL (字符串)，或者为空，我们保留原样
                    row_dict[key.strip()] = value.strip()
            
            if row_dict:
                all_rows_data.append(row_dict)

    if not all_rows_data:
        print("文件中没有找到有效数据。")
        return

    # 从第一行数据中获取所有字段名作为 CSV 的表头
    # 使用 dict.keys() 来保证顺序在 Python 3.7+ 中是插入顺序
    headers = list(all_rows_data[0].keys())
    
    print(f"共解析出 {len(all_rows_data)} 条短信。")
    print(f"正在写入到文件: {output_filepath}...")

    # 写入 CSV 文件
    # 使用 encoding='utf-8-sig' 可以让 Excel 正确识别 UTF-8 编码，避免中文乱码
    # newline='' 是写入 CSV 的标准做法，防止出现空行
    with open(output_filepath, 'w', newline='', encoding='utf-8-sig') as csvfile:
        writer = csv.DictWriter(csvfile, fieldnames=headers)
        
        # 写入表头
        writer.writeheader()
        
        # 写入所有行数据
        writer.writerows(all_rows_data)

    print(f"转换成功！文件已保存为 '{output_filepath}'。")


if __name__ == "__main__":
    # 定义输入和输出文件名
    input_file = "all_sms.txt"
    output_file = "all_sms.csv"
    
    # 执行转换
    convert_sms_to_csv(input_file, output_file)
```

将上述代码保存为 `sms_converter.py`，并与 `all_sms.txt` 放在同一目录下。随后在终端运行 `python sms_converter.py`，就会生成 `all_sms.csv` 文件。用 Excel 打开后，所有短信被清晰地排列成表格格式。

## 筛选指定SIM卡

在双卡手机上，系统会为每张SIM卡分配唯一的 **sub_id（Subscription ID）**。
 例如：

- `sub_id=0` 对应卡槽1；
- `sub_id=1` 对应卡槽2。

通过这个结果，主包可以明确地建立 `sub_id` 和具体手机卡的对应关系。在主包的案例中，`sub_id=1` 对应着主包需要处理的那张副卡。使用Excel中打开的 `all_sms.csv` 文件，选中 `sub_id` 这一列，启用筛选功能，然后只勾选值为 `1` 的行，整个表格只剩下由这张副卡接收的所有短信。主包仔细地浏览了所有验证码和通知信息，将绑定该手机号的账号一一记录下来，然后逐个进行了解绑或换绑操作。

## 总结

这一方案充分利用了 Android 系统底层的数据接口，同时避免了系统限制带来的障碍。整个流程包括：

1. 使用ADB导出短信；
2. 通过Python脚本结构化文本；
3. 在Excel中筛选特定 `sub_id`。

这种方法特别适合两类用户：

- **需要更换手机号但想保留账号信息的人**；
- **想备份短信并区分双卡短信来源的技术用户**。

这个方法尤其适用于那些不希望或无法Root手机的用户。只要你保留了完整的短信记录，并且手机卡的物理位置相对固定，那么它就能精准地帮你理清每一张SIM卡背后的数字资产。希望主包的这次实践，能为遇到同样问题的朋友们提供一个有效的参考。
