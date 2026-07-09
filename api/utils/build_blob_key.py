from app.config import LANGUAGE_NAME

def build_blob_key(lang: str, voice_name: str, ccy: str, amt: str) -> str:
    return f"audio/{voice_name}/{LANGUAGE_NAME[lang]}/{ccy.lower()}/{amt}.wav"