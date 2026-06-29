import json
import uuid
from pathlib import Path
from app.config import DB_FILE_NAME

DB_PATH = Path(DB_FILE_NAME)


def load_db() -> list:
    if not DB_PATH.exists():
        return []
    with open(DB_PATH, "r") as f:
        return json.load(f)


def save_db(data: list):
    with open(DB_PATH, "w") as f:
        json.dump(data, f, indent=2)


def find_entry_by_path(path: str) -> dict | None:
    return next((r for r in load_db() if r["path"] == path), None)


def find_entry_by_id(file_id: str) -> dict | None:
    return next((r for r in load_db() if r["id"] == file_id), None)


def add_entry(path: str) -> str:
    records = load_db()
    existing = next((r for r in records if r["path"] == path), None)
    if existing:
        return existing["id"]
    new_id = uuid.uuid4().hex  # ← change this line
    records.append({"id": new_id, "path": path})
    save_db(records)
    return new_id
