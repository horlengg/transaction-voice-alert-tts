from pathlib import Path
from fastapi import APIRouter, HTTPException
from fastapi.responses import StreamingResponse
from app.core.audio_db import find_entry_by_id,load_db

router = APIRouter(prefix="/audio", tags=["audio"])

BASE_DIR = Path("audio").resolve()

@router.get("/")
def get_audio_by_file_id():
    return load_db()

@router.get("/{file_id}")
def get_audio_by_file_id(file_id: str):
    # 1. Look up record in JSON db
    record = find_entry_by_id(file_id)
    
    if not record:
        raise HTTPException(status_code=404, detail="File ID not found.")
    
    print("-----------------------------------------------------------")
    print(f"Accessing to file => {record['path']}")
    print("-----------------------------------------------------------")
    

    # 2. Resolve and validate path
    full_path = (BASE_DIR / Path(record["path"]).relative_to("audio")).resolve()

    if not str(full_path).startswith(str(BASE_DIR)):
        raise HTTPException(status_code=403, detail="Access denied.")
    if not full_path.exists() or not full_path.is_file():
        raise HTTPException(status_code=404, detail="Audio file not found on disk.")
    if full_path.suffix.lower() != ".wav":
        raise HTTPException(status_code=403, detail="Only .wav files are accessible.")

    # 3. Stream file
    def iter_file():
        with open(full_path, "rb") as f:
            yield from f

    return StreamingResponse(
        iter_file(),
        media_type="audio/wav",
        headers={"Content-Disposition": f"attachment; filename={full_path.name}"},
    )


# @router.get("/encode")
# def encode_audio_path(path: str):
#     return {"file_id": encode_file_id(path)}