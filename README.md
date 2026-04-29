# Mini Crypto Toolkit

## 1. Overview

Mini Crypto Toolkit is an interactive Bash script that provides five cryptographic operations from a single terminal menu, plus a session log viewer. It is built for practical use of core Bash commands such as control flow, functions, loops, conditionals, input validation, file checks, and text processing that is combined with real Linux security tools.

**Features:**
- Hash any text & outputs MD5 and SHA-256 side by side
- Encode text to Base64
- Decode a Base64 string back to plaintext (with character validation via `grep -qP`)
- Encrypt text using AES-256-CBC with an explicit hex key derived from a passphrase via SHA-256
- Decrypt AES-256-CBC ciphertext, with Key (hex) and IV (hex) printed for external verification
- Save any result to an append-only session log and view it with `cat`

**Bash Commands included:**

| Concept | Where |
|---|---|
| `#!/bin/bash` | Line 1 declares the interpreter |
| `function_name() { }` | Every section is its own named function |
| `if [[ ... ]]` | Input validation, file checks, error guards |
| `case ... in` | Main menu dispatcher and save prompt |
| `while true; do` | Main menu loop and re-prompt loops |
| `for ... in ...` | `check_deps()` loops over required-tools array |
| `read -rp` | All user input prompts |
| `read -rsp` | Silent passphrase input (no echo) inside `read_secret()` |
| `IFS= read -rp` | Preserves spaces — used in `read_nonempty()`, `base64_decode()`, `aes_decrypt()` |
| `printf` | Consistent, aligned output; `printf '\n'` after silent reads |
| `exit` | Clean exit on option 7; dep-check failure exits with code 1 |
| `command -v` | Check whether each tool exists on PATH |
| `-z` | Detect empty user input |
| `-e` | Verify temp file and log file exist |
| `-r` | Confirm log file is readable before `cat` |
| `-w` | Confirm log directory is writable before appending |
| `-x` | Check if this script itself is executable |
| `awk '{print $1}'` | Strips trailing ` -` from `md5sum`/`sha256sum` output |
| `cut -d'(' -f1` | Trims label strings like `MD5(input)` → `MD5` |
| `grep -qP` | Validates Base64 character set before decode/decrypt |
| `cat` | Streams the session log to stdout |
| `\|` (pipe) | Passes text into hash, encode, and encrypt commands |
| `$(...)` | Captures command output into variables |
| `2>/dev/null` | Suppresses `openssl`/`base64` stderr on failures |
| `mktemp` | Creates a safe temp file for multi-line ciphertext |
| `trap 'rm -f ...' RETURN` | Guarantees temp file cleanup when `aes_decrypt` exits |
| `|| failed=1` | Safely captures non-zero exit codes when `pipefail` is active |

---

## 2. Dependencies

All tools are standard on Kali Linux and Debian/Ubuntu systems.

| Tool | Purpose | Package |
|---|---|---|
| `openssl` | AES-256-CBC encryption and decryption | `openssl` |
| `md5sum` | MD5 hashing | `coreutils` |
| `sha256sum` | SHA-256 hashing (also used to derive AES key from passphrase) | `coreutils` |
| `base64` | Base64 encoding and decoding | `coreutils` |
| `awk` | Field extraction from `md5sum`/`sha256sum` output | `gawk` |
| `cut` | Trims label strings in hashing output | `coreutils` |
| `grep` | Validates Base64 character set before decoding | `grep` |

Install everything at once:
```bash
sudo apt update && sudo apt install openssl coreutils gawk grep
```

The script checks all seven dependencies at startup and exits with code 1 and a clear error message if anything is missing.

---

## 3. Usage

### Make the script executable (required before first run):
```bash
chmod +x crypto_toolkit.sh
```

### Run the script:
```bash
./crypto_toolkit.sh
```

### Syntax check only (no execution):
```bash
bash -n crypto_toolkit.sh
```

### Static analysis with ShellCheck:
```bash
shellcheck crypto_toolkit.sh
```

### Debug mode (traces every command as it runs):
```bash
bash -x ./crypto_toolkit.sh
```

### Menu options:

| Option | Action |
|---|---|
| `1` | Hash text outputs MD5 and SHA-256 simultaneously |
| `2` | Base64 encode any text |
| `3` | Base64 decode a Base64 string (character set validated with `grep -qP` first) |
| `4` | Encrypt text with AES-256-CBC (passphrase confirmation required; Key and IV printed) |
| `5` | Decrypt AES-256-CBC ciphertext (re-derives key from passphrase via SHA-256) |
| `6` | View session log (`cat crypto_session.log`) |
| `7` | Exit |

### Session log:
Any result can be optionally saved to `crypto_session.log` in the current directory. The log is append-only with timestamps. Use option 6 to view it. The script checks `-w` on the directory before writing, and `-e`/`-r` before reading.

### Error recovery:
Every validation failure offers a two option recovery menu instead of crashing:
```
  What would you like to do?
  [1] Try again
  [2] Back to main menu
```

---

## 4. Example Output

```
[*] Checking required tools...
    [OK] openssl    ->  /usr/bin/openssl
    [OK] md5sum     ->  /usr/bin/md5sum
    [OK] sha256sum  ->  /usr/bin/sha256sum
    [OK] base64     ->  /usr/bin/base64
    [OK] awk        ->  /usr/bin/awk
    [OK] cut        ->  /usr/bin/cut
    [OK] grep       ->  /usr/bin/grep

=======================================
   CYBR 352 — Mini Crypto Toolkit
=======================================
  [1]  Hash text  (MD5 + SHA-256)
  [2]  Base64 encode text
  [3]  Base64 decode text
  [4]  Encrypt text  (AES-256-CBC)
  [5]  Decrypt text  (AES-256-CBC)
  [6]  View session log
  [7]  Exit
=======================================
  Choose an option [1-7]: 1

--- Results ---
Input  : hello
MD5    : 5d41402abc4b2a76b9719d911017c592
SHA256 : 2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824

Save this result to the session log? [y/n]: y
[*] Result saved to: crypto_session.log

  Choose an option [1-7]: 4

===============================
  AES-256-CBC Encrypt
===============================
Enter text to encrypt: hello CYBR352
Enter passphrase   (hidden):
Confirm passphrase (hidden):

--- Result ---
Original  : hello CYBR352
Encrypted : 4izv/QbxIjuOFzZVzwY1ew==

--- To decrypt online ---
  URL    : https://emn178.github.io/online-tools/aes/decrypt/

  Step 1  : Open the URL above in your browser
  Step 2  : Paste the Encrypted string above into the Input box
  Step 3  : Input Encoding  -> Base64
  Step 4  : Mode            -> CBC
  Step 5  : Padding         -> Pkcs7
  Step 6  : Key Type        -> Custom
  Step 7  : Key  -> Type    -> Hex
            Key  -> Data    -> 010ab04d44e42e140bc908785a5b6f1b26c182188d85a48cd05b1271b20ec112
  Step 8  : IV   -> Type    -> Hex
            IV   -> Data    -> 00000000000000000000000000000000
  Step 9  : Leave Passphrase field empty
  Step 10 : Click Decrypt

[TIP] Save the Key (hex) — you need it to decrypt.

  Choose an option [1-7]: 5

===============================
  AES-256-CBC Decrypt
===============================
  Paste or type the encrypted Base64 string.
  If it spans multiple lines, paste all lines then press Enter twice.

> 4izv/QbxIjuOFzZVzwY1ew==
Enter passphrase (hidden):

--- Result ---
Encrypted : 4izv/QbxIjuOFzZVzwY1ew==
Decrypted : hello CYBR352
```

### Error cases:

```
# Empty input
Enter text to hash: [Enter with nothing typed]
[ERROR] Input cannot be empty. Please try again.

# Invalid Base64 characters
Enter Base64 string to decode: not_valid!!!
[ERROR] Input contains characters that are not valid Base64.
        Allowed characters: A-Z  a-z  0-9  +  /  =

# Wrong passphrase on decrypt
[ERROR] Decryption failed. Wrong passphrase or corrupted ciphertext.

# Passphrase mismatch during encryption
[ERROR] Passphrases do not match.

# Invalid menu option
[ERROR] '9' is not a valid option. Enter 1-7.
```

See `output.txt` for the complete sample terminal run.

---

## 5. Functions

### `check_script_permissions()`
Checks `-x` on the script's own path (`$SCRIPT_PATH`). Prints a warning and the `chmod +x` fix command to stderr if the executable bit is not set. Does not exit — the script still runs.

**Bash concepts:** `if [[ ! -x ]]`, `echo`, `>&2`

---

### `check_deps()`
Iterates over a hardcoded array of required tools using `for ... in`. Uses `command -v` to verify each tool is on PATH. Prints `[OK] tool -> /path` for each present tool using `awk '{print $1}'` to extract the path. Exits with code 1 if any tool is missing.

**Bash concepts:** `for ... in`, `command -v`, `if [[ ]]`, `awk '{print $1}'`, `printf`, `exit 1`

---

### `read_nonempty(prompt)`
Loops until the user enters a non-empty value. Uses `IFS= read -rp` so that leading/trailing spaces and multi-word input are preserved exactly. Prints the validated value to stdout for capture by `$(...)`.

**Bash concepts:** `while true`, `IFS= read -rp`, `-z`, `echo`, `return 0`

---

### `read_secret(prompt)`
Reads a passphrase silently using `read -rsp` (no echo) and stores the result in the global variable `SECRET_VALUE` instead of printing it to stdout. This avoids running inside a subshell (via `$(...)`), which would swallow the `printf '\n'` before it reaches the terminal — causing the next prompt to appear on the same line. Callers read the value immediately after with `passphrase="$SECRET_VALUE"`.

**Bash concepts:** `read -rsp`, `printf '\n'`, `while true`, `-z`, global variable (`SECRET_VALUE`)

---

### `prompt_retry()`
Displays a two-option recovery menu (`[1] Try again` / `[2] Back to main menu`) and sets the global `RETRY_ACTION` variable to `"retry"` or `"menu"`. Resets `RETRY_ACTION` to `""` at the start of each call to prevent stale values from bleeding across function calls.

**Bash concepts:** `echo`, `read -rp`, `case ... in`, global variable assignment

---

### `save_result(label, content)`
Appends a timestamped block to `crypto_session.log`. Checks `-w` on the log directory before writing. Uses `>>` (append redirect) so existing log entries are never overwritten.

**Bash concepts:** `-w`, `$(date '+%Y-%m-%d %H:%M:%S')`, `>>`, `echo`

---

### `view_log()`
Checks `-e` (file exists) then `-r` (file is readable) before streaming the log with `cat`. Prints an informational message if no log has been created yet.

**Bash concepts:** `-e`, `-r`, `cat`, `echo`

---

### `prompt_save(label, content)`
Asks the user `"Save this result to the session log? [y/n]"` and dispatches to `save_result` on `y/Y`, or prints `"Result not saved"` otherwise.

**Bash concepts:** `read -rp`, `case ... in`

---

### `hash_text()`
Reads input via `read_nonempty` (which uses `IFS= read -rp` internally). Pipes the text into `md5sum` and `sha256sum`; extracts only the hex digest with `awk '{print $1}'`. Demonstrates `cut -d'(' -f1` by constructing strings like `"MD5(input)"` and trimming them to `"MD5"` for label formatting.

**Bash concepts:** `read_nonempty`, `printf '%s' | md5sum`, `awk`, `cut`, `pipe (|)`, `$(...)`

---

### `base64_encode()`
Reads input via `read_nonempty`. Pipes the text into `base64` and displays the encoded result. Uses `printf` for aligned output.

**Bash concepts:** `read_nonempty`, `printf '%s' | base64`, `pipe (|)`, `$(...)`

---

### `base64_decode()`
Uses `IFS= read -rp` to read the input, then `grep -qP` to validate every character against the Base64 alphabet (`^[A-Za-z0-9+/]+=*$`) before attempting decode. Captures the `base64 -d` exit code with `|| decode_failed=1` so `pipefail` cannot terminate the script on a bad string.

**Bash concepts:** `IFS= read -rp`, `grep -qP`, `pipe (|)`, `base64 -d`, `-z`, `2>/dev/null`, `|| failed=1`

---

### `aes_encrypt()`
Reads plaintext via `read -rp` and passphrase (with confirmation) via `read_secret` (result read from `$SECRET_VALUE`). Derives a 256-bit key by piping the passphrase through `sha256sum | awk '{print $1}'`. Calls `openssl enc -aes-256-cbc -K <hex_key> -iv <hex_iv> -nosalt -base64`. After encryption, prints a numbered step-by-step guide for verifying the result at `https://emn178.github.io/online-tools/aes/decrypt/`, with the actual Key (hex) and IV (hex) values embedded inline. Captures the openssl exit code with `|| encrypt_failed=1`.

**Bash concepts:** `read -rp`, `read_secret` / `SECRET_VALUE`, `sha256sum`, `awk`, `openssl enc -K -iv`, `pipe`, `$(...)`

---

### `aes_decrypt()`
Reads multi-line pasted ciphertext with an inner `while IFS= read -rp "> " line` loop that concatenates lines until a blank line or a `=`-terminated line is received. Validates the result with `grep -qP`. Re-derives the key from the passphrase via `sha256sum`. Writes ciphertext to a temp file created with `mktemp`; uses `trap 'rm -f "$tmp_file"' RETURN` to guarantee cleanup on any exit path. Captures the `openssl enc -d` exit code with `|| decrypt_failed=1`.

**Bash concepts:** `while IFS= read -rp`, `grep -qP`, `mktemp`, `-e`, `trap RETURN`, `openssl enc -d -K -iv`, `-z`, `2>/dev/null`, `rm -f`, `|| failed=1`

---

### `show_menu()`
Prints the numbered menu to stdout.

**Bash concepts:** `echo`

---

### `main()`
Entry point. Calls `check_script_permissions` and `check_deps` at startup, then runs a `while true` loop: reads the user's choice with `read -rp`, dispatches to the correct function via `case ... in`, and appends `|| true` to every function call so the loop never exits on a non-zero return.

**Bash concepts:** `while true`, `read -rp`, `case ... in`, `|| true`, `exit 0`

---

<div align="center">

### *fin*

<hr width="80px">

</div>
