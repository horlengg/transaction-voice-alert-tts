from pathlib import Path
from fastapi import APIRouter, HTTPException, Response
from app.storage import list_all_blobs,blob_client

from dotenv import load_dotenv

load_dotenv()  


router = APIRouter(prefix="/audio", tags=["audio"])

BASE_DIR = Path("audio").resolve()

@router.get("/")
async def get_audio_by_file_id():
    return await list_all_blobs()

@router.get("/{file_path:path}")
async def get_audio_by_file_id(file_path: str):
    blob_key = f"audio/{file_path}"  # re-add the "audio/" prefix stripped by the router prefix

    try:
        result = await blob_client.get(blob_key, access="private")
    except Exception:
        raise HTTPException(status_code=404, detail="File not found")

    return Response(content=result.content, media_type=result.content_type or "audio/wav")