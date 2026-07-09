import edge_tts
import asyncio
import io
import subprocess
import tempfile
from pathlib import Path
from app.config import ENGLISH_VOICE, KHMER_VOICE
import imageio_ffmpeg


def get_edge_tts_voice(voice_name: str, language_code: str) -> str:
    if language_code == 'en-us':
        return ENGLISH_VOICE[voice_name]
    return KHMER_VOICE[voice_name]

def convert_audio(wav_bytes: bytes, output_format: str) -> bytes:
    """Convert audio bytes (MP3 from edge_tts) to target format using FFmpeg."""
    # ✅ Use .mp3 suffix so FFmpeg detects the input format correctly
    with tempfile.NamedTemporaryFile(suffix=".mp3", delete=False) as tmp_in:
        tmp_in.write(wav_bytes)
        tmp_in_path = tmp_in.name

    tmp_out_path = tmp_in_path.replace(".mp3", f".{output_format}")

    format_map = {
        "caf": "caf",
        "mp3": "mp3",
        "wav": "wav",
    }

    codec_map = {
        "caf": "pcm_s16le",
        "mp3": "libmp3lame",
        "wav": "pcm_s16le",
    }

    try:
        ffmpeg_exe = imageio_ffmpeg.get_ffmpeg_exe()

        subprocess.run(
            [
                ffmpeg_exe, "-y", "-i", tmp_in_path,
                "-ar", "22050",
                "-ac", "1",
                "-f", format_map[output_format],
                "-c:a", codec_map[output_format],
                tmp_out_path,
            ],
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        return Path(tmp_out_path).read_bytes()
    except subprocess.CalledProcessError as e:
        raise RuntimeError(f"FFmpeg conversion to {output_format} failed: {e.stderr.decode()}")
    finally:
        Path(tmp_in_path).unlink(missing_ok=True)
        Path(tmp_out_path).unlink(missing_ok=True)


async def _generate_trx_audio(tts_text: str, voice_name: str, language_code: str, output_format: str = "wav") -> bytes:
    edge_tts_voice = get_edge_tts_voice(voice_name, language_code)
    audio_bytes = io.BytesIO()
    communicator = edge_tts.Communicate(text=tts_text, voice=edge_tts_voice)
    async for chunk in communicator.stream():
        if chunk["type"] == "audio":
            audio_bytes.write(chunk["data"])
    audio_bytes.seek(0)
    raw_bytes = audio_bytes.read()

    # run blocking FFmpeg subprocess in a thread so it doesn't block the event loop
    return await asyncio.to_thread(convert_audio, raw_bytes, output_format)


def generate_trx_audio(tts_text: str, voice_name: str, language_code: str, output_format: str = "wav") -> bytes:
    return asyncio.run(_generate_trx_audio(tts_text, voice_name, language_code, output_format))
