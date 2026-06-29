

from pathlib import Path
from app.config import LANGUAGE_NAME


def build_audio_path(lang:str,voice_name:str,ccy:str,amt:str) -> Path :
    return Path(f"audio/{voice_name}/{LANGUAGE_NAME[lang]}/{ccy.lower()}/{amt}.wav")