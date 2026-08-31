# Correctif icône officielle Les Twiix

Ce patch remplace l'icône Flutter par le logo officiel Les Twiix fourni dans la conversation.

Il conserve le principe actuel du projet : le dossier Android est généré par GitHub Actions, puis les icônes Twiix sont copiées juste avant la compilation de l'APK.

## Depuis Termux
Depuis le dossier du dépôt `Les_Twiix_App_V0_1` :

```bash
unzip -o ~/storage/downloads/Les_Twiix_Correctif_Logo_Officiel.zip -d .
git add .
git commit -m "Logo officiel Les Twiix"
git push
```

Puis aller dans GitHub > Les-Twiix-App > Actions et attendre le nouveau build.
L'artifact à télécharger s'appelle `Les-Twiix-APK`.
