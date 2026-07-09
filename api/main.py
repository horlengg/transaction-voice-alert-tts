from fastapi import Depends, FastAPI
from app.routers import speech,audio
from app.auth import verify_api_key
from dotenv import load_dotenv

load_dotenv()  

app = FastAPI(title="OpenAI TTS", version="1.0.0")

app.include_router(audio.router, prefix="/openai/api/v1")
app.include_router(
    speech.router,
    prefix="/openai/api/v1",
    dependencies=[Depends(verify_api_key)],
)

@app.get("/health", tags=["health"])
def health():
    return {"status": "ok" }