# Crypto-Toolkit

# Mini Crypto Toolkit

A beginner-friendly Bash script that demonstrates core Linux and Bash concepts
alongside practical cryptography commands.

## Features

| Option | Description                                     |
| ------ | ----------------------------------------------- |
| 1      | Hash text with **MD5**                          |
| 2      | Hash text with **SHA-256**                      |
| 3      | **Base64 encode** text                          |
| 4      | **Base64 decode** text                          |
| 5      | **Encrypt** text with AES-256-CBC (via OpenSSL) |
| 6      | **Decrypt** text with AES-256-CBC (via OpenSSL) |
| 7      | Exit                                            |

## Requirements

The following tools must be installed on your system:

- `openssl`
- `md5sum`
- `sha256sum`
- `base64`

On most Debian/Ubuntu systems these are already available.  
Install any missing tools with:

```bash
sudo apt-get install openssl coreutils
```

## Folder Structure

```
Mini-Crypto-Toolkit/
├── crypto_toolkit.sh   # Main script
├── README.md           # This file
├── references.txt      # Sources and references
├── output.txt          # Auto-generated operation log
└── assets/
    └── screenshots/    # Screenshots of the toolkit in action
```

## How to Run

1. Make the script executable:

   ```bash
   chmod +x crypto_toolkit.sh
   ```

2. Run it:

   ```bash
   ./crypto_toolkit.sh
   ```

## Usage Examples

### Hash Text

```
Enter your choice [1-7]: 1
Enter text to hash (MD5): hello world
  Input : hello world
  MD5   : 5eb63bbbe01eeed093cb22bb8f5acdc3
```

### Base64 Encode / Decode

```
Enter your choice [1-7]: 3
Enter text to Base64 encode: hello
  Input  : hello
  Encoded: aGVsbG8=
```

```
Enter your choice [1-7]: 4
Enter Base64 text to decode: aGVsbG8=
  Encoded : aGVsbG8=
  Decoded : hello
```

### Encrypt / Decrypt with AES

```
Enter your choice [1-7]: 5
Enter text to encrypt: secret message
Enter encryption password: ****
  Encrypted (Base64): U2FsdGVkX1...
```

```
Enter your choice [1-7]: 6
Enter encrypted text (Base64): U2FsdGVkX1...
Enter decryption password: ****
  Decrypted: secret message
```

## Bash Concepts Used

| Concept                   | Where Used                       |
| ------------------------- | -------------------------------- |
| `#!/bin/bash` shebang     | Top of `crypto_toolkit.sh`       |
| `function_name() { ... }` | Every feature is a function      |
| `if [[ ... ]]`            | Input validation, error checks   |
| `case ... in`             | Menu choice dispatch             |
| `while true; do ... done` | Main menu loop                   |
| `for ... in ...`          | Dependency check loop            |
| `read -p`                 | User prompts                     |
| `echo`                    | Output messages                  |
| `exit`                    | Quit the program                 |
| `command -v`              | Check tool existence             |
| `-z`                      | Empty-input check                |
| `-e` / `-w`               | Log file existence / writability |
| `awk`                     | Extract hash value from output   |
| `grep -qE`                | Validate Base64 character set    |
| `\|` (pipe)               | Pass text into crypto commands   |
| `$(...)`                  | Capture command output           |
| `2>/dev/null`             | Suppress error output            |

## Output Log

Every operation is appended to `output.txt` automatically:

```
-------------------------------------------
Operation : MD5
Input     : hello world
Output    : d8e8fca2dc0f896fd7cb4cb0031ba249
Timestamp : 2025-01-01 12:00:00
```

## Screenshots

Screenshots of the toolkit running are located in `assets/screenshots/`.

## License

This project is for educational purposes.
