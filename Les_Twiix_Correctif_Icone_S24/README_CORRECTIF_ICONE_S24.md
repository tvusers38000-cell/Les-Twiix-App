# Correctif icône S24 Ultra — Les Twiix

Ce correctif règle le cas où Samsung/Android continue d'afficher l'icône Flutter bleue.

La cause : `flutter create` recrée les ressources Android et ajoute une icône adaptative Flutter prioritaire sur Android 8+.

Le workflow applique maintenant le logo officiel Les Twiix **après** `flutter create`, remplace toutes les densités d'icône et retire les deux XML d'icône adaptative Flutter afin que le launcher Samsung utilise le logo Twiix.

Depuis le dossier du dépôt :

```bash
unzip -o ~/storage/downloads/Les_Twiix_Correctif_Icone_S24.zip -d .
git add .
git commit -m "Correctif icone Twiix S24"
git push
```
