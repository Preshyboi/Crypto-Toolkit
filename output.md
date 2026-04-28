# Mini Crypto Toolkit — Sample Run Output

**Course:** CYBR 352 — Linux Fundamentals  
**Script:** `crypto_toolkit.sh`  
**Purpose:** Annotated sample output for screenshots

---

## Startup — Dependency Check

```
[*] Checking required tools...
    [OK] openssl    ->  /usr/bin/openssl
    [OK] md5sum     ->  /usr/bin/md5sum
    [OK] sha256sum  ->  /usr/bin/sha256sum
    [OK] base64     ->  /usr/bin/base64
    [OK] awk        ->  /usr/bin/awk
    [OK] cut        ->  /usr/bin/cut
    [OK] grep       ->  /usr/bin/grep
```

---

## Main Menu

```
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
  Choose an option [1-7]:
```

---

## Option 1 — Hash Text

### Normal run

```
  Choose an option [1-7]: 1

===============================
  Hash Text  (MD5 + SHA-256)
===============================
  (Accepts single words AND full sentences)

Enter text to hash: hello CYBR352

--- Results ---
Input  : hello CYBR352
MD5    : e43c311ff3967964312ea3cb6d89ba18
SHA256 : 3b49e48c8a4e0b9dae6b83f60570da6400afcd9bc7ca27826d098e97d898cb5d

Save this result to the session log? [y/n]: y
[*] Result saved to: crypto_session.log
```

### Error — empty input, then retry

```
  Choose an option [1-7]: 1

===============================
  Hash Text  (MD5 + SHA-256)
===============================
  (Accepts single words AND full sentences)

Enter text to hash:
[ERROR] Input cannot be empty. Please try again.

Enter text to hash: hello CYBR352

--- Results ---
Input  : hello CYBR352
MD5    : e43c311ff3967964312ea3cb6d89ba18
SHA256 : 3b49e48c8a4e0b9dae6b83f60570da6400afcd9bc7ca27826d098e97d898cb5d

Save this result to the session log? [y/n]: n
[*] Result not saved.
```

---

## Option 2 — Base64 Encode

```
  Choose an option [1-7]: 2

===============================
  Base64 Encode
===============================
Enter text to encode: hello CYBR352

--- Result ---
Original : hello CYBR352
Encoded  : aGVsbG8gQ1lCUjM1Mg==

Save this result to the session log? [y/n]: y
[*] Result saved to: crypto_session.log
```

---

## Option 3 — Base64 Decode

### Normal run

```
  Choose an option [1-7]: 3

===============================
  Base64 Decode
===============================
Enter Base64 string to decode: aGVsbG8gQ1lCUjM1Mg==

--- Result ---
Encoded  : aGVsbG8gQ1lCUjM1Mg==
Decoded  : hello CYBR352

Save this result to the session log? [y/n]: n
[*] Result not saved.
```

### Error — invalid characters, then back to menu

```
  Choose an option [1-7]: 3

===============================
  Base64 Decode
===============================
Enter Base64 string to decode: not_valid!!!

[ERROR] Input contains characters that are not valid Base64.
        Allowed characters: A-Z  a-z  0-9  +  /  =

  What would you like to do?
  [1] Try again
  [2] Back to main menu
  Choose [1-2]: 2
```

---

## Option 4 — AES-256-CBC Encrypt

### Normal run

```
  Choose an option [1-7]: 4

===============================
  AES-256-CBC Encrypt
===============================
Enter text to encrypt: hello CYBR352
Enter passphrase   (hidden):
Confirm passphrase (hidden):

--- Result ---
Original  : hello CYBR352
Encrypted : 2pQlhoibxh+pZ9Yv8CrzMg==

--- To decrypt online ---
  URL    : https://emn178.github.io/online-tools/aes/decrypt/

  Step 1  : Open the URL above in your browser
  Step 2  : Paste the Encrypted string above into the Input box
  Step 3  : Input Encoding  -> Base64
  Step 4  : Mode            -> CBC
  Step 5  : Padding         -> Pkcs7
  Step 6  : Key Type        -> Custom
  Step 7  : Key  -> Type    -> Hex
            Key  -> Data    -> a753971d9d65ad49b0a9a0581bf717aa0f8bc4aa9e6c0dfb5ff50de2f38c75ad
  Step 8  : IV   -> Type    -> Hex
            IV   -> Data    -> 00000000000000000000000000000000
  Step 9  : Leave Passphrase field empty
  Step 10 : Click Decrypt

[TIP] Save the Key (hex) — you need it to decrypt.

Save this result to the session log? [y/n]: y
[*] Result saved to: crypto_session.log
```

### Error — passphrase mismatch, then retry

```
  Choose an option [1-7]: 4

===============================
  AES-256-CBC Encrypt
===============================
Enter text to encrypt: hello CYBR352
Enter passphrase   (hidden):
Confirm passphrase (hidden):
[ERROR] Passphrases do not match.

  What would you like to do?
  [1] Try again
  [2] Back to main menu
  Choose [1-2]: 1

Enter passphrase   (hidden):
Confirm passphrase (hidden):

--- Result ---
Original  : hello CYBR352
Encrypted : 2pQlhoibxh+pZ9Yv8CrzMg==

[TIP] Save the Key (hex) — you need it to decrypt.

Save this result to the session log? [y/n]: n
[*] Result not saved.
```

---

## Option 5 — AES-256-CBC Decrypt

### Normal run

```
  Choose an option [1-7]: 5

===============================
  AES-256-CBC Decrypt
===============================
  Paste or type the encrypted Base64 string.
  If it spans multiple lines, paste all lines then press Enter twice.

> 2pQlhoibxh+pZ9Yv8CrzMg==
Enter passphrase (hidden):

--- Result ---
Encrypted : 2pQlhoibxh+pZ9Yv8CrzMg==
Decrypted : hello CYBR352

Save this result to the session log? [y/n]: y
[*] Result saved to: crypto_session.log
```

### Error — wrong passphrase, then retry with correct passphrase

```
  Choose an option [1-7]: 5

===============================
  AES-256-CBC Decrypt
===============================
  Paste or type the encrypted Base64 string.
  If it spans multiple lines, paste all lines then press Enter twice.

> 2pQlhoibxh+pZ9Yv8CrzMg==
Enter passphrase (hidden):

[ERROR] Decryption failed. Wrong passphrase or corrupted ciphertext.

  What would you like to do?
  [1] Try again
  [2] Back to main menu
  Choose [1-2]: 1

  Paste or type the encrypted Base64 string.
  If it spans multiple lines, paste all lines then press Enter twice.

> 2pQlhoibxh+pZ9Yv8CrzMg==
Enter passphrase (hidden):

--- Result ---
Encrypted : 2pQlhoibxh+pZ9Yv8CrzMg==
Decrypted : hello CYBR352

Save this result to the session log? [y/n]: n
[*] Result not saved.
```

---

## Option 6 — View Session Log

### With saved entries

```
  Choose an option [1-7]: 6

===============================
  Session Log
===============================
========================================
  [HASH]  2026-04-29 10:14:02
========================================
Input   : hello CYBR352
MD5     : e43c311ff3967964312ea3cb6d89ba18
SHA-256 : 3b49e48c8a4e0b9dae6b83f60570da6400afcd9bc7ca27826d098e97d898cb5d

========================================
  [BASE64-ENCODE]  2026-04-29 10:15:18
========================================
Original : hello CYBR352
Encoded  : aGVsbG8gQ1lCUjM1Mg==

========================================
  [AES-ENCRYPT]  2026-04-29 10:16:45
========================================
Original  : hello CYBR352
Encrypted : 2pQlhoibxh+pZ9Yv8CrzMg==
Key (hex) : a753971d9d65ad49b0a9a0581bf717aa0f8bc4aa9e6c0dfb5ff50de2f38c75ad
IV  (hex) : 00000000000000000000000000000000

========================================
  [AES-DECRYPT]  2026-04-29 10:17:33
========================================
Encrypted : 2pQlhoibxh+pZ9Yv8CrzMg==
Decrypted : hello CYBR352
```

### Empty — nothing saved yet

```
  Choose an option [1-7]: 6

===============================
  Session Log
===============================
[INFO] No session log found. Nothing has been saved yet.
```

---

## Invalid Menu Option

```
  Choose an option [1-7]: 9
[ERROR] '9' is not a valid option. Enter 1-7.
```

---

## Option 7 — Exit

```
  Choose an option [1-7]: 7
[*] Exiting Mini Crypto Toolkit. Goodbye!
```
