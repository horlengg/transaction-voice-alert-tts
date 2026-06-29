
from fastapi import HTTPException
import app.config as config
from utils.number_to_khmer import number_to_khmer


def to_khmer_digits(amount: str) -> str:
    return amount.translate(config.KHMER_DIGITS)

def split_usd_amount(amount: str) -> tuple[str, str]:
    if "." in amount:
        dollars, cents = amount.split(".", 1)
        cents = cents.ljust(2, "0")[:2]
    else:
        dollars, cents = amount, "00"
    return dollars, cents

def validate_trx_request(voice_name: str, language_code: str, trx_amount: str, trx_currency: str):
    errors = []

    if voice_name not in config.SUPPORTED_VOICES:
        errors.append("Voice not supported")

    # 2. Language
    if language_code not in config.SUPPORTED_LANGUAGES:
        errors.append(f"Unsupported language '{language_code}'. Supported: {sorted(config.SUPPORTED_LANGUAGES)}.")

    # 3. Currency
    currency_upper = trx_currency.upper()
    if currency_upper not in config.SUPPORTED_CURRENCIES:
        errors.append(f"Unsupported currency '{trx_currency}'. Supported: {sorted(config.SUPPORTED_CURRENCIES)}.")

    # 4. Amount — must be numeric
    try:
        amount_value = float(trx_amount)
    except ValueError:
        errors.append(f"trxAmount '{trx_amount}' is not a valid number.")
        raise HTTPException(status_code=422, detail=errors)  # stop early, further checks need float

    # 5. Amount must be positive
    if amount_value <= 0:
        errors.append("trxAmount must be greater than 0.")

    # 6. KHR must not have decimals
    if currency_upper == "KHR" and "." in trx_amount:
        errors.append("trxAmount must not contain decimals when currency is KHR.")

    # 7. USD decimal places must not exceed 2
    if currency_upper == "USD" and "." in trx_amount:
        _, decimals = trx_amount.split(".", 1)
        if len(decimals) > 2:
            errors.append(f"trxAmount for USD must have at most 2 decimal places, got {len(decimals)}.")

    # 8. Amount must not be negative zero or suspiciously large
    if amount_value > 999_999_999:
        errors.append("trxAmount exceeds maximum allowed value (999,999,999).")

    if errors:
        raise HTTPException(status_code=422, detail=errors)


def build_tts_text(language_code: str, trx_amount: str, trx_currency: str) -> str:
    lang_key = "km-kh" if language_code == "km-kh" else "en"
    currency_upper = trx_currency.upper()

    if currency_upper == "USD":
        dollars, cents = split_usd_amount(trx_amount)
        has_cents = cents != "00"

        if lang_key == "km-kh":
            kh_dollars = number_to_khmer(dollars)   # ✅ words, not digits
            kh_cents = number_to_khmer(cents)        # ✅ words, not digits
            if has_cents:
                return f"ទទួលបាន {kh_dollars} ដុល្លា {kh_cents} សេន"
            else:
                return f"ទទួលបាន {kh_dollars} ដុល្លា"
        else:
            if has_cents:
                return f"Received {dollars} dollar and {cents} cent"
            else:
                return f"Received {dollars} dollar"

    else:
        currency_map = config.CURRENCY_DISPLAY.get(lang_key, config.CURRENCY_DISPLAY["en"])
        currency_label = currency_map.get(currency_upper, trx_currency)

        if lang_key == "km-kh":
            kh_amount = number_to_khmer(trx_amount)  # ✅ words, not digits
            return f"ទទួលបាន {kh_amount} {currency_label}"
        else:
            return f"Received {trx_amount} {currency_label}"