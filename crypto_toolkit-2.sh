#!/bin/bash
# =============================================================================
# crypto_toolkit.sh — Mini Crypto Toolkit
# Course  : CYBR 352 — Linux Fundamentals
# Topic   : Encryption / Encoding / Hashing Toolkit
# Tools   : openssl, md5sum, sha256sum, base64, awk, cut, grep
# =============================================================================

# NOTE: We intentionally do NOT use "set -e" here.
# With -e, any function that returns non-zero on a bad input would kill the 
# entire script. Instead, we handle every error manually inside
# each function and let the main loop always keep running.
set -uo pipefail

# =============================================================================
# GLOBAL CONFIG
# =============================================================================

LOG_FILE="crypto_session.log"
SCRIPT_PATH="$(realpath "$0")"

# =============================================================================
# SECTION 1 — STARTUP CHECKS
# =============================================================================

check_script_permissions() {
    # -x : true if the file has the executable bit set
    if [[ ! -x "$SCRIPT_PATH" ]]; then
        echo "[WARN] This script is not marked executable." >&2
        echo "[WARN] Run:  chmod +x $SCRIPT_PATH" >&2
        echo ""
    fi
}

# check_dependencies
# Uses: for...in, command -v, if [[ ]], awk, echo, exit
check_deps() {
    local -a REQUIRED_TOOLS=("openssl" "md5sum" "sha256sum" "base64"
                              "awk" "cut" "grep")
    local missing=0

    echo "[*] Checking required tools..."

    for tool in "${REQUIRED_TOOLS[@]}"; do
        if command -v "$tool" > /dev/null 2>&1; then
            # awk '{print $1}' — keep only the path, discard any extra output
            local tool_path
            tool_path=$(command -v "$tool" | awk '{print $1}')
            printf "    [OK] %-10s ->  %s\n" "$tool" "$tool_path"
        else
            echo "    [MISSING] $tool — install with: sudo apt install $tool" >&2
            missing=1
        fi
    done

    echo ""

    if [[ $missing -eq 1 ]]; then
        echo "[ERROR] One or more required tools are missing. Cannot continue." >&2
        exit 1
    fi
}

# =============================================================================
# SECTION 2 — INPUT HELPERS
# =============================================================================

# read_nonempty PROMPT
# Loops until the user enters a non-empty value; prints result to stdout
# for capture via $(...).
# Uses: while true, IFS= read -rp, -z, echo, return 0
read_nonempty() {
    local prompt="$1"
    local value=""

    while true; do
        # IFS= : disable word-splitting so leading/trailing spaces are kept
        IFS= read -rp "$prompt" value
        if [[ -z "$value" ]]; then
            echo "[ERROR] Input cannot be empty. Please try again." >&2
        else
            echo "$value"
            return 0
        fi
    done
}

# read_secret PROMPT
# Reads a passphrase silently (no echo) and stores it in the global
# SECRET_VALUE variable. Uses a global instead of stdout so that
# printf '\n' — which must go to the terminal — is never swallowed
# by a subshell when the caller does passphrase=$(read_secret ...).
#
# Usage:  read_secret "Enter passphrase: "
#         passphrase="$SECRET_VALUE"
#
# Uses: while true, read -rsp, printf '\n', -z, return 0
SECRET_VALUE=""   # global written by read_secret; read by callers immediately after

read_secret() {
    local prompt="$1"
    SECRET_VALUE=""

    while true; do
        read -rsp "$prompt" SECRET_VALUE
        # printf '\n' writes directly to the terminal (fd 1 of the outer shell),
        # not into a subshell pipe — guaranteed newline after every silent read.
        printf '\n'
        if [[ -z "$SECRET_VALUE" ]]; then
            echo "[ERROR] Passphrase cannot be empty. Please try again." >&2
        else
            return 0
        fi
    done
}

# =============================================================================
# SECTION 3 — ERROR RECOVERY PROMPT
# Instead of crashing out, every error calls prompt_retry.
# prompt_retry shows two choices: retype input OR go back to main menu.
# It sets the global RETRY_ACTION variable which callers check.
#
# Uses: echo, read -rp, case
# =============================================================================

RETRY_ACTION=""   # set to "retry" or "menu" by prompt_retry

prompt_retry() {
    # Reset before each use so a stale value from a previous call
    # can never bleed into the next function that reads RETRY_ACTION.
    RETRY_ACTION=""

    echo ""
    echo "  What would you like to do?"
    echo "  [1] Try again"
    echo "  [2] Back to main menu"

    while true; do
        read -rp "  Choose [1-2]: " retry_choice
        case "$retry_choice" in
            1)
                RETRY_ACTION="retry"
                return 0
                ;;
            2)
                RETRY_ACTION="menu"
                return 0
                ;;
            *)
                echo "[ERROR] Please enter 1 or 2." >&2
                ;;
        esac
    done
}

# =============================================================================
# SECTION 4 — SESSION LOG HELPERS
# Uses: -w, -e, -r, cat, echo
# =============================================================================

save_result() {
    local label="$1"
    local content="$2"
    local log_dir
    log_dir="$(dirname "$LOG_FILE")"

    # -w : check the directory is writable before appending
    if [[ ! -w "$log_dir" ]]; then
        echo "[ERROR] Cannot write to log directory: $log_dir" >&2
        return 1
    fi

    {
        echo "========================================"
        echo "  [$label]  $(date '+%Y-%m-%d %H:%M:%S')"
        echo "========================================"
        echo "$content"
        echo ""
    } >> "$LOG_FILE"

    echo "[*] Result saved to: $LOG_FILE"
}

# view_log
# Uses: -e, -r, cat
view_log() {
    echo ""
    echo "==============================="
    echo "  Session Log"
    echo "==============================="

    # -e : true if file exists on disk
    if [[ ! -e "$LOG_FILE" ]]; then
        echo "[INFO] No session log found. Nothing has been saved yet."
        echo ""
        return 0
    fi

    # -r : true if file is readable
    if [[ ! -r "$LOG_FILE" ]]; then
        echo "[ERROR] Log file exists but cannot be read: $LOG_FILE" >&2
        return 1
    fi

    cat "$LOG_FILE"
    echo ""
}

# prompt_save LABEL CONTENT
# Uses: read -rp, case
prompt_save() {
    local label="$1"
    local content="$2"

    read -rp "Save this result to the session log? [y/n]: " save_choice
    case "$save_choice" in
        y|Y) save_result "$label" "$content" ;;
        *)   echo "[*] Result not saved." ;;
    esac
    echo ""
}

# =============================================================================
# SECTION 5 — HASHING
# Uses: while true, read_nonempty (IFS= read -rp internally), printf | md5sum,
#       awk '{print $1}', cut -d'(' -f1, pipe, $(...), prompt_retry
#
# NOTE on IFS= read -rp (inside read_nonempty):
# Plain read splits on $IFS (space/tab/newline), stripping leading/trailing
# spaces from input. Setting IFS= (empty) preserves the entire line exactly.
#
# NOTE on cut -d'(' -f1:
# The labels "MD5" and "SHA256" are embedded inside constructed strings so
# that cut can be demonstrated trimming them — showing the concept of
# splitting on a delimiter and keeping a specific field.
# =============================================================================

hash_text() {
    echo ""
    echo "==============================="
    echo "  Hash Text  (MD5 + SHA-256)"
    echo "==============================="
    echo "  (Accepts single words AND full sentences)"
    echo ""

    local text=""

    # while true : keep looping until we get valid input or user goes to menu
    while true; do
        # read_nonempty handles the IFS= read -rp loop and empty-input check
        text=$(read_nonempty "Enter text to hash: ")

        # -z safety net — read_nonempty should never return empty, but guard anyway
        if [[ -z "$text" ]]; then
            echo "[ERROR] Input cannot be empty." >&2
            prompt_retry
            [[ "$RETRY_ACTION" == "menu" ]] && return 0
            continue
        fi

        break
    done

    # printf '%s' preserves spaces and special characters in $text exactly.
    # Pipe into md5sum; awk '{print $1}' extracts only the hex digest,
    # dropping the trailing ' -' that md5sum appends.
    local md5_result
    md5_result=$(printf '%s' "$text" | md5sum | awk '{print $1}')

    # Same pattern for sha256sum
    local sha256_result
    sha256_result=$(printf '%s' "$text" | sha256sum | awk '{print $1}')

    # cut -d'(' -f1 : split on '(' and keep field 1.
    # e.g. "MD5(input)" → "MD5"  |  "SHA256(input)" → "SHA256"
    local md5_label sha256_label
    md5_label=$(echo "MD5(input)"     | cut -d'(' -f1)
    sha256_label=$(echo "SHA256(input)" | cut -d'(' -f1)

    echo ""
    echo "--- Results ---"
    printf "Input  : %s\n" "$text"
    printf "%s    : %s\n" "$md5_label" "$md5_result"
    printf "%s : %s\n"    "$sha256_label" "$sha256_result"
    echo ""

    prompt_save "HASH" "Input   : $text
MD5     : $md5_result
SHA-256 : $sha256_result"
}

# =============================================================================
# SECTION 6 — BASE64 ENCODE
# Uses: read_nonempty (IFS= read -rp internally), printf | base64, pipe, $(...)
# =============================================================================

base64_encode() {
    echo ""
    echo "==============================="
    echo "  Base64 Encode"
    echo "==============================="

    # read_nonempty re-prompts automatically on empty input
    local text
    text=$(read_nonempty "Enter text to encode: ")

    local encoded
    encoded=$(printf '%s' "$text" | base64)

    echo ""
    echo "--- Result ---"
    printf "Original : %s\n" "$text"
    printf "Encoded  : %s\n" "$encoded"
    echo ""

    prompt_save "BASE64-ENCODE" "Original : $text
Encoded  : $encoded"
}

# =============================================================================
# SECTION 7 — BASE64 DECODE
# Uses: grep -qP (character validation), IFS= read -rp, pipe, base64 -d,
#       if [[ -z ]], 2>/dev/null, prompt_retry, while true
#
# FIX: The previous version used:
#       if ! decoded=$(echo "$encoded" | base64 -d 2>/dev/null)
# With "set -o pipefail", if base64 -d exits non-zero the entire pipe fails
# and the script can terminate before prompt_retry fires.
# Fix: capture exit code with "|| decode_failed=1" pattern.
# =============================================================================

base64_decode() {
    echo ""
    echo "==============================="
    echo "  Base64 Decode"
    echo "==============================="

    local encoded=""
    local decoded=""

    # Loop until we get a successful decode or the user goes back to menu
    while true; do
        # IFS= : preserve any spaces in the encoded string exactly as typed
        IFS= read -rp "Enter Base64 string to decode: " encoded

        # -z : reject empty input
        if [[ -z "$encoded" ]]; then
            echo "[ERROR] Input cannot be empty." >&2
            prompt_retry
            [[ "$RETRY_ACTION" == "menu" ]] && return 0
            continue
        fi

        # grep -qP : validate every character is a legal Base64 character.
        # Valid alphabet: A-Z  a-z  0-9  +  /  with '=' padding only at end.
        # -q suppresses match output; non-zero exit = illegal character found.
        if ! echo "$encoded" | grep -qP '^[A-Za-z0-9+/]+=*$'; then
            echo ""
            echo "[ERROR] Input contains characters that are not valid Base64." >&2
            echo "        Allowed characters: A-Z  a-z  0-9  +  /  =" >&2
            prompt_retry
            [[ "$RETRY_ACTION" == "menu" ]] && return 0
            continue
        fi

        # Capture output and exit code separately so pipefail
        # cannot kill the script if base64 -d returns non-zero.
        local decode_failed=0
        decoded=$(echo "$encoded" | base64 -d 2>/dev/null) || decode_failed=1

        if [[ $decode_failed -eq 1 ]]; then
            echo ""
            echo "[ERROR] Base64 decoding failed. The string may be malformed." >&2
            prompt_retry
            [[ "$RETRY_ACTION" == "menu" ]] && return 0
            continue
        fi

        # -z : confirm the decoded result is not empty
        if [[ -z "$decoded" ]]; then
            echo ""
            echo "[ERROR] Decoded result is empty — input may be malformed." >&2
            prompt_retry
            [[ "$RETRY_ACTION" == "menu" ]] && return 0
            continue
        fi

        # All checks passed now exit the loop
        break
    done

    echo ""
    echo "--- Result ---"
    printf "Encoded  : %s\n" "$encoded"
    printf "Decoded  : %s\n" "$decoded"
    echo ""

    prompt_save "BASE64-DECODE" "Encoded  : $encoded
Decoded  : $decoded"
}

# =============================================================================
# SECTION 8 — AES-256-CBC ENCRYPT
#
# Key derivation: passphrase to SHA-256 then 64 hex chars = 32 bytes = 256-bit key
# IV: 32 hex zeros (16 zero bytes, fixed) printed so the user can verify
#     on any external AES-256-CBC tool
# Mode: -nosalt (salt is only meaningful with -pbkdf2 / -pass)
#
# Uses: read_nonempty, read_secret, sha256sum, awk, openssl enc -K -iv,
#       pipe, $(...), if [[ ]], 2>/dev/null, prompt_retry, while true
# =============================================================================

aes_encrypt() {
    echo ""
    echo "==============================="
    echo "  AES-256-CBC Encrypt"
    echo "==============================="

    local text=""
    local passphrase=""
    local confirm=""

    # --- Get plaintext ---
    while true; do
        read -rp "Enter text to encrypt: " text

        if [[ -z "$text" ]]; then
            echo "[ERROR] Input cannot be empty." >&2
            prompt_retry
            [[ "$RETRY_ACTION" == "menu" ]] && return 0
            continue
        fi
        break
    done

    # --- Get and confirm passphrase ---
    # read_secret writes to $SECRET_VALUE (not stdout) so printf '\n' reaches
    # the terminal correctly — no subshell swallowing the newline.
    while true; do
        read_secret "Enter passphrase   (hidden): ";   passphrase="$SECRET_VALUE"
        read_secret "Confirm passphrase (hidden): ";   confirm="$SECRET_VALUE"

        if [[ "$passphrase" != "$confirm" ]]; then
            echo "[ERROR] Passphrases do not match." >&2
            prompt_retry
            [[ "$RETRY_ACTION" == "menu" ]] && return 0
            continue
        fi

        break
    done

    # --- Derive 256-bit key from passphrase using SHA-256 ---
    # sha256sum outputs "hexdigest  -"; awk '{print $1}' keeps only the hex
    local key_hex
    key_hex=$(printf '%s' "$passphrase" | sha256sum | awk '{print $1}')

    # Fixed 128-bit IV (16 zero bytes in hex).
    # Printed to screen so the user can replicate in any online AES-CBC tool.
    local iv_hex="00000000000000000000000000000000"

    # Encrypt with explicit hex key and IV (no openssl-proprietary KDF).
    #   -aes-256-cbc : cipher
    #   -K           : supply raw key as hex (bypasses openssl's own KDF)
    #   -iv          : supply raw IV as hex
    #   -nosalt      : no salt header — required when using -K/-iv directly
    #   -base64      : encode ciphertext as Base64 for safe text output
    local encrypt_failed=0
    local encrypted
    encrypted=$(printf '%s' "$text" \
        | openssl enc -aes-256-cbc \
            -K  "$key_hex" \
            -iv "$iv_hex" \
            -nosalt -base64 2>/dev/null) || encrypt_failed=1

    if [[ $encrypt_failed -eq 1 ]]; then
        echo "[ERROR] Encryption failed. Check that openssl is working." >&2
        prompt_retry
        [[ "$RETRY_ACTION" == "menu" ]] && return 0
        aes_encrypt   # retry — restart from the top
        return 0
    fi

    echo ""
    echo "--- Result ---"
    printf "Original  : %s\n" "$text"
    printf "Encrypted : %s\n" "$encrypted"
    echo ""
    echo "--- To decrypt online ---"
    echo "  URL    : https://emn178.github.io/online-tools/aes/decrypt/"
    echo ""
    echo "  Step 1  : Open the URL above in your browser"
    echo "  Step 2  : Paste the Encrypted string above into the Input box"
    echo "  Step 3  : Input Encoding  -> Base64"
    echo "  Step 4  : Mode            -> CBC"
    echo "  Step 5  : Padding         -> Pkcs7"
    echo "  Step 6  : Key Type        -> Custom"
    echo "  Step 7  : Key  -> Type    -> Hex"
    printf "            Key  -> Data    -> %s\n" "$key_hex"
    echo "  Step 8  : IV   -> Type    -> Hex"
    printf "            IV   -> Data    -> %s\n" "$iv_hex"
    echo "  Step 9  : Leave Passphrase field empty"
    echo "  Step 10 : Click Decrypt"
    echo ""
    echo "[TIP] Save the Key (hex) — you need it to decrypt."
    echo ""

    prompt_save "AES-ENCRYPT" "Original  : $text
Encrypted : $encrypted
Key (hex) : $key_hex
IV  (hex) : $iv_hex"
}

# =============================================================================
# SECTION 9 — AES-256-CBC DECRYPT
#
# FIX 1 — Multi-line pasted ciphertext crash:
#   "read -rp" only captures one line. Pasting a wrapped Base64 string sent
#   the second line to the shell as a command → crash.
#   Fix: inner while loop concatenates lines until a blank line or a line
#   ending in '=' (Base64 padding) signals the end of input.
#
# FIX 2 — pipefail kills script on wrong passphrase:
#   "if ! decrypted=$(openssl ...)" — with pipefail, a non-zero exit from
#   openssl propagates before the if-check can run.
#   Fix: use "|| decrypt_failed=1" to capture failure safely.
#
# FIX 3 — Passphrase prompt on same line:
#   "echo ''" after read -rsp can be swallowed in some terminals.
#   Fix: printf '\n' guarantees exactly one newline immediately.
#
# Uses: IFS= read -rp, while true, grep -qP, read_secret, printf,
#       sha256sum, awk, mktemp, -e, openssl enc -d -K -iv,
#       -z, 2>/dev/null, rm -f, trap, prompt_retry
# =============================================================================

aes_decrypt() {
    echo ""
    echo "==============================="
    echo "  AES-256-CBC Decrypt"
    echo "==============================="

    local encrypted=""
    local passphrase=""

    # --- Get ciphertext (handles single-line AND multi-line pasted strings) ---
    while true; do
        echo "  Paste or type the encrypted Base64 string."
        echo "  If it spans multiple lines, paste all lines then press Enter twice."
        echo ""

        local line=""
        encrypted=""

        # Read lines one at a time and concatenate.
        # Ends when: blank line entered (user signals done),
        # OR a line ending in '=' (complete Base64 with padding).
        while IFS= read -rp "> " line; do
            [[ -z "$line" ]] && break           # blank line = done
            encrypted="${encrypted}${line}"
            [[ "$line" == *"=" ]] && break      # padding found = complete string
        done

        # -z : nothing was entered at all
        if [[ -z "$encrypted" ]]; then
            echo "[ERROR] Input cannot be empty." >&2
            prompt_retry
            [[ "$RETRY_ACTION" == "menu" ]] && return 0
            continue
        fi

        # grep -qP : confirm the concatenated string is valid Base64
        if ! echo "$encrypted" | grep -qP '^[A-Za-z0-9+/]+=*$'; then
            echo ""
            echo "[ERROR] Ciphertext does not look like valid Base64." >&2
            echo "        Allowed characters: A-Z  a-z  0-9  +  /  =" >&2
            prompt_retry
            [[ "$RETRY_ACTION" == "menu" ]] && return 0
            continue
        fi

        break   
    done

    # --- Get passphrase (read_secret writes to $SECRET_VALUE, not stdout) ---
    read_secret "Enter passphrase (hidden): "
    passphrase="$SECRET_VALUE"

    # --- Re-derive the 256-bit key from the passphrase ---
    local key_hex
    key_hex=$(printf '%s' "$passphrase" | sha256sum | awk '{print $1}')

    local iv_hex="00000000000000000000000000000000"

    # Write ciphertext to a temp file.
    # openssl handles multi-line / concatenated Base64 from a file correctly.
    local tmp_file
    tmp_file=$(mktemp /tmp/crypto_toolkit_XXXXXX)

    # trap : guarantee temp file is removed even if the function exits early
    trap 'rm -f "$tmp_file"' RETURN

    # -e : confirm the temp file was created successfully before writing
    if [[ ! -e "$tmp_file" ]]; then
        echo "[ERROR] Could not create a temporary file." >&2
        prompt_retry
        [[ "$RETRY_ACTION" == "menu" ]] && return 0
        aes_decrypt
        return 0
    fi

    printf '%s\n' "$encrypted" > "$tmp_file"

    # Capture openssl exit code safely — || prevents pipefail from killing
    # the script if openssl returns non-zero (wrong passphrase, bad data, etc.)
    local decrypted=""
    local decrypt_failed=0
    decrypted=$(openssl enc -aes-256-cbc \
        -d \
        -K  "$key_hex" \
        -iv "$iv_hex" \
        -nosalt -base64 \
        -in "$tmp_file" 2>/dev/null) || decrypt_failed=1

    if [[ $decrypt_failed -eq 1 ]]; then
        echo ""
        echo "[ERROR] Decryption failed. Wrong passphrase or corrupted ciphertext." >&2
        prompt_retry
        [[ "$RETRY_ACTION" == "menu" ]] && return 0
        aes_decrypt
        return 0
    fi

    # -z : a successful decrypt of non-empty plaintext should never be empty
    if [[ -z "$decrypted" ]]; then
        echo ""
        echo "[ERROR] Decrypted result is empty — ciphertext may be malformed." >&2
        prompt_retry
        [[ "$RETRY_ACTION" == "menu" ]] && return 0
        aes_decrypt
        return 0
    fi

    echo ""
    echo "--- Result ---"
    printf "Encrypted : %s\n" "$encrypted"
    printf "Decrypted : %s\n" "$decrypted"
    echo ""

    prompt_save "AES-DECRYPT" "Encrypted : $encrypted
Decrypted : $decrypted"
}

# =============================================================================
# SECTION 10 — MAIN MENU
# Uses: show_menu, while true, read -rp, case, exit
# =============================================================================

show_menu() {
    echo "======================================="
    echo "   CYBR 352 — Mini Crypto Toolkit"
    echo "======================================="
    echo "  [1]  Hash text  (MD5 + SHA-256)"
    echo "  [2]  Base64 encode text"
    echo "  [3]  Base64 decode text"
    echo "  [4]  Encrypt text  (AES-256-CBC)"
    echo "  [5]  Decrypt text  (AES-256-CBC)"
    echo "  [6]  View session log"
    echo "  [7]  Exit"
    echo "======================================="
}

main() {
    check_script_permissions
    check_deps

    # while true : keep showing the menu until the user picks Exit (7)
    while true; do

        show_menu
        read -rp "  Choose an option [1-7]: " choice
        echo ""

        # case : dispatch to the right function.
        # Every function is called with || true so that even if the function
        # returns non-zero, the while loop does NOT exit.
        case "$choice" in
            1) hash_text      || true ;;
            2) base64_encode  || true ;;
            3) base64_decode  || true ;;
            4) aes_encrypt    || true ;;
            5) aes_decrypt    || true ;;
            6) view_log       || true ;;
            7)
                echo "[*] Exiting Mini Crypto Toolkit. Goodbye!"
                echo ""
                exit 0
                ;;
            *)
                echo "[ERROR] '$choice' is not a valid option. Enter 1-7." >&2
                echo ""
                ;;
        esac

    done
}

main
