import os

from fastapi import Depends, FastAPI
from fastapi.responses import JSONResponse
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



APP_ID = os.environ["APP_ID"]

# Explore Universal Domain
AASA_DATA = {
    "applinks": {
        "apps": [],
        "details": [
            {
                "appIDs": [APP_ID],
                "components": [
                    {
                        "/": "/*",
                        "comment": "Matches all paths"
                    }
                ]
            }
        ]
    }
}

# 1. Primary endpoint required by Apple
@app.api_route(
    "/.well-known/apple-app-site-association", 
    methods=["GET", "HEAD"], 
    response_class=JSONResponse
)
@app.api_route(
    "/apple-app-site-association", 
    methods=["GET", "HEAD"], 
    response_class=JSONResponse
)
async def get_aasa():
    return JSONResponse(content=AASA_DATA, media_type="application/json")