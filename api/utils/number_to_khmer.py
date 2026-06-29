"""
Khmer Number to Words Converter
Logic ported from AmountToWordsConverterUtil.swift (Houleng.LY, 21/6/26)

Example:
    "120000" => "មួយសែនពីរម៉ឺន"
    "21"     => "ម្ភៃមួយ"
"""

# Index 0 unused; index 1-9 = ones
KHMER_DIGITS = [
    "", "មួយ", "ពីរ", "បី", "បួន", "ប្រាំ",
    "ប្រាំមួយ", "ប្រាំពីរ", "ប្រាំបី", "ប្រាំបួន",
]

# Index 0 = 10 (ដប់), index 1 = 11 (ដប់មួយ), ..., index 9 = 19 (ដប់ប្រាំបួន)
KHMER_TEENS = [
    "ដប់", "ដប់មួយ", "ដប់ពីរ", "ដប់បី", "ដប់បួន",
    "ដប់ប្រាំ", "ដប់ប្រាំមួយ", "ដប់ប្រាំពីរ", "ដប់ប្រាំបី", "ដប់ប្រាំបួន",
]

# Index 0-1 unused; index 2-9 = twenty through ninety
KHMER_TENS = [
    "", "", "ម្ភៃ", "សាមសិប", "សែសិប", "ហាសិប",
    "ហុកសិប", "ចិតសិប", "ប៉ែតសិប", "កៅសិប",
]

PLACE_VALUES = [
    (1_000_000, "លាន"),
    (100_000,   "សែន"),
    (10_000,    "ម៉ឺន"),
    (1_000,     "ពាន់"),
    (100,       "រយ"),
    (10,        "ដប់"),   # sentinel — handled specially below
]


def _khmer_words(number: int) -> str:
    """Convert a non-negative integer to Khmer words (mirrors khmerWords() in Swift)."""
    if number == 0:
        return "សូន្យ"

    remaining = number
    words = ""

    for value, name in PLACE_VALUES:
        count = remaining // value
        if count > 0:
            if value == 1_000_000:
                # Recursively convert the millions count (e.g. 10_000_000 → ដប់លាន)
                words += _khmer_words(count) + name
            elif value == 10:
                # Tens: use teens table for 10-19, tens table for 20-99
                tens_digit = remaining // 10       # could be 1-9
                ones_digit = remaining % 10
                if tens_digit == 1:
                    # 10-19 → use KHMER_TEENS
                    words += KHMER_TEENS[ones_digit]
                    remaining = 0
                    break
                else:
                    words += KHMER_TENS[tens_digit]
            else:
                words += KHMER_DIGITS[count] + name
            remaining -= count * value

    # Remaining ones (only reached when we didn't break out of tens handling)
    if remaining > 0:
        words += KHMER_DIGITS[remaining]

    return words


def number_to_khmer(amount: str) -> str:
    """
    Convert an amount string into Khmer words.

    Args:
        amount: A non-negative integer string, e.g. "120000"

    Returns:
        Khmer word string, e.g. "មួយសែនពីរម៉ឺន"

    Raises:
        ValueError: If the input is not a valid non-negative integer string.
    """
    amount = amount.strip().replace(",", "").replace("_", "")

    if not amount.isdigit():
        raise ValueError(
            f"Invalid amount string: '{amount}'. Only non-negative integers are supported."
        )

    return _khmer_words(int(amount))


# ── Self-test ────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    cases = [
        ("0",         "សូន្យ"),
        ("1",         "មួយ"),
        ("9",         "ប្រាំបួន"),
        ("10",        "ដប់"),
        ("11",        "ដប់មួយ"),
        ("19",        "ដប់ប្រាំបួន"),
        ("20",        "ម្ភៃ"),
        ("21",        "ម្ភៃមួយ"),
        ("30",        "សាមសិប"),
        ("99",        "កៅសិបប្រាំបួន"),
        ("100",       "មួយរយ"),
        ("115",       "មួយរយដប់ប្រាំ"),
        ("120",       "មួយរយម្ភៃ"),
        ("1000",      "មួយពាន់"),
        ("1500",      "មួយពាន់ប្រាំរយ"),
        ("10000",     "មួយម៉ឺន"),
        ("12000",     "មួយម៉ឺនពីរពាន់"),
        ("120000",    "មួយសែនពីរម៉ឺន"),
        ("1000000",   "មួយលាន"),
        ("10000000",  "ដប់លាន"),
        ("21000000",  "ម្ភៃមួយលាន"),
    ]

    pass_count = 0
    for amount, expected in cases:
        result = number_to_khmer(amount)
        status = "✅" if result == expected else "❌"
        if result != expected:
            print(f"  {status} {amount:>12} => {result}  (expected: {expected})")
        else:
            print(f"  {status} {amount:>12} => {result}")
            pass_count += 1

    print(f"\n{pass_count}/{len(cases)} passed")