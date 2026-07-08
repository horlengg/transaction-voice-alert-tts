

ENGLISH_VOICE = {
    "sreymom" : "en-US-JennyNeural",
    "piseth" : "en-US-GuyNeural"
}

KHMER_VOICE = {
    "piseth" : "km-KH-PisethNeural",
    "sreymom" : "km-KH-SreymomNeural"
}

LANGUAGE_NAME = {
    "en-us" : "english",
    "km-kh" : "khmer"
}

CURRENCY_DISPLAY = {
    "en": {"USD": "dollar", "KHR": "riel"},
    "km-kh": {"USD": "ដុល្លា", "KHR": "រៀល"},
}

KHMER_DIGITS = str.maketrans("0123456789", "០១២៣៤៥៦៧៨៩")

SUPPORTED_CURRENCIES = {"USD", "KHR"}

SUPPORTED_LANGUAGES = {"en-us", "km-kh"}
SUPPORTED_VOICES = {"piseth", "sreymom"}
DB_FILE_NAME = "tb_trx_audio_file.json"


MEDIA_TYPES = {
    "wav": "audio/wav",
    "caf": "audio/x-caf",
    "mp3": "audio/mpeg",
}