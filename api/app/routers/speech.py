import io
from pathlib import Path
from fastapi import APIRouter, HTTPException
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
from utils import build_tts_text, validate_trx_request,build_audio_path
from app.core.audio_db import add_entry
from app.core import generate_trx_audio
import app.config as config
from typing import Literal

router = APIRouter(prefix="/speech", tags=["speech"])


class SpeechRequest(BaseModel):
    message: str
    language: str = "km-kh"
    voiceId: int = 147328
    speechModel: str = "mars-81-flash"


class SpeechRequest(BaseModel):
    trxAmount: str
    trxCurrency: str
    format: Literal["wav", "caf", "mp3"] = "wav"

# @router.post("/{voice_name}/{language_code}/generate")
# def generate_speech(voice_name: str, language_code: str, request: SpeechRequest):
#     tts_text = build_tts_text(language_code, request.trxAmount, request.trxCurrency.upper())
#     print("Generating:", tts_text)

#     try:
#         raw_bytes = generate_trx_audio(tts_text, voice_name, language_code, output_format=request.format)

#         return StreamingResponse(
#             io.BytesIO(raw_bytes),
#             media_type=config.MEDIA_TYPES.get(request.format, "audio/wav"),
#             headers={"Content-Disposition": f"attachment; filename=paysound.{request.format}"},
#         )
#     except Exception as e:
#         raise HTTPException(status_code=500, detail=str(e))
    

@router.post("/{voice_name}/{language_code}/generate")
def generate_trx_speech(voice_name: str, language_code: str, request: SpeechRequest):
    trx_amount = request.trxAmount.replace(",", "")
    trx_currency = request.trxCurrency.upper()

    validate_trx_request(voice_name, language_code, trx_amount, trx_currency)

    cache_path = build_audio_path(lang=language_code,voice_name=voice_name,ccy=trx_currency,amt=trx_amount)
    path_str = str(cache_path)

    if cache_path.exists():
        add_entry(path_str)

        def iter_cached():
            with open(cache_path, "rb") as f:
                yield from f

        return StreamingResponse(
            iter_cached(),
            media_type="audio/wav",
            headers={"Content-Disposition": "attachment; filename=paysound.wav"},
        )

    tts_text = build_tts_text(language_code, trx_amount, trx_currency)
    print("Generating:", tts_text)

    try:
        raw_bytes = generate_trx_audio(tts_text, voice_name, language_code)

        cache_path.parent.mkdir(parents=True, exist_ok=True)
        with open(cache_path, "wb") as f:
            f.write(raw_bytes)

        add_entry(path_str)

        return StreamingResponse(
            io.BytesIO(raw_bytes),
            media_type="audio/wav",
            headers={"Content-Disposition": "attachment; filename=paysound.wav"},
        )

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))