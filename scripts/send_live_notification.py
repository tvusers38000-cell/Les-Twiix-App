import json
import os

import firebase_admin
from firebase_admin import credentials, messaging


def send_live_notification():
    if os.environ.get("ENABLE_LIVE_NOTIFICATIONS") != "true":
        print("Envoi désactivé : mode sécurisé.")
        return

    secret = os.environ.get("FIREBASE_SERVICE_ACCOUNT")
    if not secret:
        raise RuntimeError("Secret Firebase manquant")

    service_account = json.loads(secret)

    firebase_admin.initialize_app(
        credentials.Certificate(service_account)
    )

    message = messaging.Message(
        notification=messaging.Notification(
            title="Les Twiix sont en LIVE !",
            body="Rejoins-nous maintenant sur TikTok !",
        ),
        data={
            "url": "https://www.tiktok.com/@les_twiix/live",
        },
        topic="twiix_live",
    )

    result = messaging.send(message)
    print("Notification envoyée :", result)


if __name__ == "__main__":
    send_live_notification()
