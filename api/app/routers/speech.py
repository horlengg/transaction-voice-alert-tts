import io
import os
import traceback
from fastapi import APIRouter, BackgroundTasks, HTTPException, Response
from pydantic import BaseModel
from typing import Literal
from utils import build_tts_text, validate_trx_request, build_blob_key
from app.core import _generate_trx_audio
from dotenv import load_dotenv
from app.storage import blob_exists,upload_to_blob,blob_client

load_dotenv()  


router = APIRouter(prefix="/speech", tags=["speech"])

BLOB_TOKEN = os.environ["BLOB_READ_WRITE_TOKEN"]
BLOB_API_URL = "https://blob.vercel-storage.com"


class SpeechRequest(BaseModel):
    trxAmount: str
    trxCurrency: str
    format: Literal["wav", "caf", "mp3"] = "wav"


@router.post("/{voice_name}/{language_code}/generate")
async def generate_trx_speech(
    voice_name: str,
    language_code: str,
    request: SpeechRequest,
    background_tasks: BackgroundTasks,
):
    trx_amount = request.trxAmount.replace(",", "")
    trx_currency = request.trxCurrency.upper()

    validate_trx_request(voice_name, language_code, trx_amount, trx_currency)

    blob_key = build_blob_key(
        lang=language_code, voice_name=voice_name, ccy=trx_currency, amt=trx_amount
    )

    # 1. Check cache in Blob
    cached_url = await blob_exists(blob_key)
    if cached_url:
        result = await blob_client.get(blob_key, access="private")
        return Response(content=result.content, media_type=result.content_type or "audio/wav")

    # 2. Generate audio, return it immediately, upload in background
    tts_text = build_tts_text(language_code, trx_amount, trx_currency)
    print("Generating:", tts_text)

    try:
        raw_bytes = await _generate_trx_audio(tts_text, voice_name, language_code)

        # schedule upload to run AFTER the response is sent to the client
        background_tasks.add_task(_upload_safely, blob_key, raw_bytes)

        return Response(content=raw_bytes, media_type="audio/wav")

    except Exception as e:
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))


async def _upload_safely(blob_key: str, raw_bytes: bytes):
    """Runs after the response is returned — failures here shouldn't affect the user."""
    try:
        await upload_to_blob(blob_key, raw_bytes, content_type="audio/wav")
        # print("Done upload file!.")
    except Exception:
        traceback.print_exc()
