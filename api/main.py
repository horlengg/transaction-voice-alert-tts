from fastapi import FastAPI
from app.routers import speech, audio
from utils.number_to_khmer import number_to_khmer

app = FastAPI(title="OpenAI TTS", version="1.0.0")

app.include_router(speech.router, prefix="/openai/api/v1")
app.include_router(audio.router, prefix="/openai/api/v1")

print()

@app.get("/health", tags=["health"])
def health():
    return {"status": "ok" }