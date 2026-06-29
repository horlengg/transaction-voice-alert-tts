import base64
import string
from cryptography.fernet import Fernet
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
import os
from fastapi import HTTPException

BASE62_CHARS = string.digits + string.ascii_letters  # 0-9A-Za-z

def base62_encode(data: bytes) -> str:
    num = int.from_bytes(data, "big")
    if num == 0:
        return BASE62_CHARS[0]
    result = []
    while num:
        result.append(BASE62_CHARS[num % 62])
        num //= 62
    # Preserve leading zero bytes
    result.extend(BASE62_CHARS[0] for _ in range(len(data) - len(data.lstrip(b"\x00"))))
    return "".join(reversed(result))

def base62_decode(token: str) -> bytes:
    num = 0
    for char in token:
        if char not in BASE62_CHARS:
            raise HTTPException(status_code=400, detail="Invalid file ID characters.")
        num = num * 62 + BASE62_CHARS.index(char)
    # Calculate byte length
    byte_length = (num.bit_length() + 7) // 8
    return num.to_bytes(byte_length, "big")

def get_fernet() -> Fernet:
    password = os.getenv("FILE_ID_SECRET", "changeme").encode()
    salt = os.getenv("FILE_ID_SALT", "static_salt_16b!!").encode()[:16]
    kdf = PBKDF2HMAC(algorithm=hashes.SHA256(), length=32, salt=salt, iterations=100_000)
    key = base64.urlsafe_b64encode(kdf.derive(password))
    return Fernet(key)

def encode_file_id(file_path: str) -> str:
    """'TrxAudio/147328/km-kh/1000/KHR/paysound.wav' → alphanumeric only token"""
    encrypted_bytes = get_fernet().encrypt(file_path.encode())
    return base62_encode(encrypted_bytes)  # only 0-9 A-Z a-z

def decode_file_id(file_id: str) -> str:
    """alphanumeric token → 'TrxAudio/147328/km-kh/1000/KHR/paysound.wav'"""
    try:
        encrypted_bytes = base62_decode(file_id)
        return get_fernet().decrypt(encrypted_bytes).decode()
    except HTTPException:
        raise
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid or tampered file ID.")
    