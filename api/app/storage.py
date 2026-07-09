from vercel.blob import AsyncBlobClient
from dotenv import load_dotenv


load_dotenv()

blob_client = AsyncBlobClient()  # reads BLOB_READ_WRITE_TOKEN from env

async def upload_to_blob(key: str, data: bytes, content_type: str) -> str:
    result = await blob_client.put(
        key,
        data,
        access="private",
        content_type=content_type,
        add_random_suffix=False,
    )
    return result.url


async def blob_exists(key: str) -> str | None:
    try:
        meta = await blob_client.head(key)  # or a full URL if you have one
        return meta.url
    except Exception:
        return None
    
async def list_all_blobs(prefix: str | None = None) -> list[dict]:
    all_blobs = []
    cursor = None

    while True:
        result = await blob_client.list_objects(
            prefix=prefix,
            cursor=cursor,
            limit=1000,
        )
        all_blobs.extend(
            {
                "pathname": b.pathname,
                "url": b.url,
                "download_url": b.download_url,
                "size": b.size,
                "uploaded_at": b.uploaded_at.isoformat(),
            }
            for b in result.blobs
        )

        if not result.has_more or not result.cursor:
            break
        cursor = result.cursor

    return all_blobs