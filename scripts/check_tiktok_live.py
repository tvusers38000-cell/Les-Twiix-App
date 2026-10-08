import asyncio
import os
import sys

from TikTokLive import TikTokLiveClient


async def main():
    username = os.environ.get(
        "TIKTOK_USERNAME", "les_twiix"
    ).lstrip("@")

    client = TikTokLiveClient(
        unique_id=f"@{username}"
    )

    try:
        live = await asyncio.wait_for(
            client.is_live(),
            timeout=45,
        )
    except Exception as exc:
        print(
            f"ERREUR : {type(exc).__name__}: {exc}"
        )
        sys.exit(1)

    print(f"Compte : @{username}")
    print(
        "État : EN LIVE"
        if live
        else "État : HORS LIVE"
    )

    if live:
        room_id = getattr(client, "room_id", None)
        print(f"Identifiant LIVE : {room_id or 'indisponible'}")

    print("Diagnostic uniquement : aucune notification envoyée.")


if __name__ == "__main__":
    asyncio.run(main())
