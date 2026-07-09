import io
import os
import traceback
from fastapi import APIRouter, HTTPException, Response
from pydantic import BaseModel
from typing import Literal
from utils import build_tts_text, validate_trx_request, build_blob_key
from app.core import _generate_trx_audio
from dotenv import load_dotenv
from app.storage import blob_exists,upload_to_blob,blob_client
from fastapi.responses import StreamingResponse

load_dotenv()  


router = APIRouter(prefix="/speech", tags=["speech"])

BLOB_TOKEN = os.environ["BLOB_READ_WRITE_TOKEN"]
BLOB_API_URL = "https://blob.vercel-storage.com"


class SpeechRequest(BaseModel):
    trxAmount: str
    trxCurrency: str
    format: Literal["wav", "caf", "mp3"] = "wav"


@router.post("/{voice_name}/{language_code}/generate")
async def generate_trx_speech(voice_name: str, language_code: str, request: SpeechRequest):
    trx_amount = request.trxAmount.replace(",", "")
    trx_currency = request.trxCurrency.upper()

    validate_trx_request(voice_name, language_code, trx_amount, trx_currency)

    blob_key = build_blob_key(
        lang=language_code, voice_name=voice_name, ccy=trx_currency, amt=trx_amount
    )  # e.g. "speech/sreymom/km-kh/KHR-200000.wav"

    # 1. Check cache in Blob
    cached_url = await blob_exists(blob_key)
    if cached_url:
        result = await blob_client.get(blob_key, access="private")
        return Response(content=result.content, media_type=result.content_type or "audio/wav")

    # 2. Generate + upload
    tts_text = build_tts_text(language_code, trx_amount, trx_currency)
    print("Generating:", tts_text)

    try:
        raw_bytes = await _generate_trx_audio(tts_text, voice_name, language_code)
        await upload_to_blob(blob_key, raw_bytes, content_type="audio/wav")
        return StreamingResponse(io.BytesIO(raw_bytes), media_type="audio/wav")

    except Exception as e:
        traceback.print_exc()  # <--- This prints the line + specific error to your terminal logs
        raise HTTPException(status_code=500, detail=str(e))
    
