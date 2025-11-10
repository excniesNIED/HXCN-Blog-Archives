# Must-Read Before Swapping SIMs: Using ADB to Export and Filter All SMS Messages by Specific SIM Card

## Prequel

My current phone plan's promotional offer was about to expire, so I planned to switch to a new SIM card and phone number. The problem was that my old number was tied to a significant number of online accounts, and I had no clear record of just how many.

The built-in "Messages" app on my Huawei phone, unfortunately, does not support filtering messages by SIM card. I attempted to use several third-party SMS management apps like SMS Tools, DekuSMS, and SmsForwarder. The results were disappointing: some were long abandoned and wouldn't run, while others could only handle newly received messages, not existing historical data. Due to system restrictions on my Huawei device, standard users are prohibited from accessing the raw SMS database path (`/data/data/com.android.providers.telephony/databases/mmssms.db`). Since my phone is not rooted, this path was completely inaccessible.

After hitting several dead ends, I realized a more fundamental, application-independent solution was necessary: **ADB (Android Debug Bridge)**. ADB is a powerful command-line tool that allows developers to deeply communicate with and control an Android device. Crucially for my needs, it provides access to the system's underlying **Content Provider**, which is the interface to the SMS database.

## Exporting SMS Records

Before starting, you must enable "Developer Options" and "USB Debugging" in your phone's system settings. This is the foundation for allowing your computer to communicate with the phone via ADB. Once the preparations were complete, I connected my phone to my computer, installed ADB, and confirmed the connection in the terminal:

```
./adb devices
```

A successful response (showing the device ID as "connected") confirmed the link.

Next, I executed the following command:

```bash
adb shell content query --uri content://sms/
```

This command directly outputs all records from the SMS database, including the sender's number, timestamp, message body, and the crucial SIM card identifier. To access other system logs like call records or contacts, you can simply replace the URI:

For example:

```bash
adb shell content query --uri content://call_log/calls
adb shell content query --uri content://contacts/phones/
```

However, ADB outputs the SMS content in an **unstructured text format**, where each record is stored as "key=value" pairs with no standardized record separator. It's virtually unreadable and impossible to filter directly. Therefore, I redirected the output to a text file:

```bash
adb shell content query --uri content://sms/ > all_sms.txt
```

This step resulted in a file containing thousands of raw records.

## Text Structuring

The `all_sms.txt` file is plain text but contains a complex key-value structure, like this example row:

```
Row: 1 _id=2982, thread_id=1402, address=106819388006257049, person=0, date=1761720271713, date_sent=1761720269000, protocol=0, read=1, status=-1, type=1, reply_path_present=0, subject=NULL, body=【滴滴出行】验证码：(114514)，您正在使用短信验证码登录功能，2分钟内有效。转发可能导致帐号被盗，请勿泄露给他人   , service_center=+8615654161, locked=0, sub_id=1, network_type=13, error_code=0, creator=com.android.mms, seen=1, si_id=NULL, mid=NULL, created=NULL, mtype=0, privacy_mode=0, group_id=7627, addr_body=0,, time_body=0,, risk_url_body=, is_secret=1, resent_im=0, hw_is_satellite=0
```

Each line consists of multiple `key=value` fields separated by commas. For instance, `address=` is the sender's number, `body=` is the message content, and `date=` is the timestamp.

Opening this directly in Excel is pointless. To properly analyze these fields, I wrote a **Python conversion script**. The core idea is to use a regular expression to identify the pattern of "a comma immediately followed by a key=" to split each line into a dictionary of fields, which can then be uniformly written to a CSV file.

The script automatically handles special characters like commas or equal signs within the SMS body to prevent incorrect splitting. Each record is converted into a single row of data, with columns for fields like `_id`, `address`, `body`, and most importantly, `sub_id`.

```python
import csv
import re
import os

def convert_sms_to_csv(input_filepath, output_filepath):
    """
    Converts an SMS text file exported via the adb command into CSV format.

    Args:
        input_filepath (str): Path to the input txt file (all_sms.txt).
        output_filepath (str): Path to the output csv file.
    """
    # Regular expression: Splits by a comma, but only if the comma is
    # immediately followed by a "key=value" pattern (positive lookahead).
    # \s* matches 0 or more whitespace characters
    # (?=\w+=) is a positive lookahead, finding a "word=" pattern without consuming characters.
    # This ensures splitting only happens between fields, not within field content.
    # E.g., for "body=..., service_center=...", it splits at ", ".
    pattern = re.compile(r',\s*(?=\w+=)')

    all_rows_data = []
    
    # Check if input file exists
    if not os.path.exists(input_filepath):
        print(f"Error: Input file '{input_filepath}' does not exist.")
        return

    print(f"Reading file: {input_filepath}...")
    
    with open(input_filepath, 'r', encoding='utf-8') as f:
        for i, line in enumerate(f):
            # Remove the leading "Row: x " part and trailing whitespace
            # Find the position of the first field "_id=" and slice from there for robustness
            start_index = line.find('_id=')
            if start_index == -1:
                print(f"Warning: Line {i+1} has an incorrect format and was skipped: {line.strip()}")
                continue
            
            content = line[start_index:].strip()

            # Use the regex pattern to split into "key=value" blocks
            fields = pattern.split(content)
            
            row_dict = {}
            for field in fields:
                # Split only on the *first* equal sign, to handle values that contain an equal sign
                parts = field.split('=', 1)
                if len(parts) == 2:
                    key, value = parts
                    # Values can be 'NULL' (as a string) or empty; preserve them as is
                    row_dict[key.strip()] = value.strip()
            
            if row_dict:
                all_rows_data.append(row_dict)

    if not all_rows_data:
        print("No valid data found in the file.")
        return

    # Get all field names from the first row as the CSV header
    # Using dict.keys() guarantees insertion order on Python 3.7+
    headers = list(all_rows_data[0].keys())
    
    print(f"Successfully parsed {len(all_rows_data)} SMS messages.")
    print(f"Writing to file: {output_filepath}...")

    # Write the CSV file
    # Using encoding='utf-8-sig' allows Excel to correctly recognize UTF-8 encoding
    # newline='' is standard practice when writing CSVs to prevent extra blank lines
    with open(output_filepath, 'w', newline='', encoding='utf-8-sig') as csvfile:
        writer = csv.DictWriter(csvfile, fieldnames=headers)
        
        # Write header row
        writer.writeheader()
        
        # Write all data rows
        writer.writerows(all_rows_data)

    print(f"Conversion successful! File saved as '{output_filepath}'.")


if __name__ == "__main__":
    # Define input and output filenames
    input_file = "all_sms.txt"
    output_file = "all_sms.csv"
    
    # Execute the conversion
    convert_sms_to_csv(input_file, output_file)
```

I saved the code above as `sms_converter.py` and placed it in the same directory as `all_sms.txt`. Running `python sms_converter.py` in the terminal generated the `all_sms.csv` file, with all messages neatly structured into a table.

## Filtering by Specific SIM Card

On a dual-SIM phone, the system assigns a unique **`sub_id` (Subscription ID)** to each SIM card. For example, the values often map like this:

- `sub_id=0` corresponds to SIM Slot 1;
- `sub_id=1` corresponds to SIM Slot 2.

This field allowed me to definitively link the `sub_id` to the physical phone number I needed to check. In my case, `sub_id=1` corresponded to the secondary SIM card that was about to be decommissioned.

Using the newly created `all_sms.csv` file, I opened it in Excel (or any spreadsheet program), selected the `sub_id` column, and applied a filter, selecting only the rows where the value was `1`. The resulting filtered table showed every message received or sent by that specific SIM card. I meticulously reviewed all verification codes and notification messages, recording every account tied to that number, and then proceeded to unlink or swap the phone number for each of them.

## Conclusion

This solution successfully leveraged the underlying data interfaces of the Android system while completely bypassing the restrictions imposed by my device's operating system and lack of root access. The entire process involved three core steps:

1.  **ADB Export:** Using `adb shell content query` to extract raw SMS data.
2.  **Python Structuring:** Employing a script to parse the raw text into a clear CSV format.
3.  **Spreadsheet Filtering:** Using the `sub_id` column in Excel to isolate messages from the specific SIM card.

This method is particularly valuable for two types of users:

-   **Those who need to change phone numbers but want to retain associated account information.**
-   **Technical users backing up their data who need to differentiate between messages from dual SIM cards.**

It is an especially effective workaround for users who cannot or do not wish to root their devices. As long as you have your complete message history and your SIM card slots remain physically consistent, this technique can accurately help you catalog the digital assets tied to each of your phone numbers. I hope this practical exercise provides a useful reference for anyone facing similar issues.