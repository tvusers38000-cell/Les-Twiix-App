# LES TWIIX — Prototype Flutter V0.1

Prototype communautaire Android/iOS avec données de démonstration.

## Inclus dans cette version
- Accueil / actus communautaires
- Planning des lives
- Défis & Twiix Points
- Hall of Fame / Top donateurs
- Profil + aperçu de l'espace Admin
- Identité visuelle sombre rose/bleu inspirée des visuels fournis
- Logo et planning fournis intégrés comme assets
- Build Android automatique via GitHub Actions
- Structure Flutter compatible Android et iOS

## Tester sur Android avec GitHub
1. Créer un nouveau dépôt GitHub (ex: `Les-Twiix-App`).
2. Envoyer tout le contenu de ce dossier dans le dépôt.
3. Ouvrir l'onglet **Actions** sur GitHub.
4. Lancer `Build Android APK` (ou pousser un commit sur `main`).
5. Télécharger l'artefact **Les-Twiix-APK**.
6. Extraire `app-debug.apk` et l'installer sur Android.

Le workflow génère automatiquement les dossiers Android/iOS s'ils n'existent pas, puis compile l'APK de test.

## Important
Cette V0.1 utilise uniquement des données locales de démonstration. Aucun compte, aucune notification push et aucune donnée TikTok ne sont encore connectés.

La V0.2 pourra ajouter :
- Firebase/Supabase
- authentification membres/admins/modérateurs
- panneau Admin réel
- notifications push
- contenu dynamique
- gestion du Top donateurs
- modération / signalement
- préparation TestFlight iOS

## Identifiant provisoire
Organisation Flutter : `com.lestwiix`

L'identifiant définitif Play Store/App Store sera figé avant publication publique.
