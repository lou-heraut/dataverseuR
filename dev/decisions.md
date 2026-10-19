# Décisions

Les choix qui ont émergé du travail, avec leur date et leur raison.

## 2026-10-19

Issus de l'audit `dev/audits/2026-10-19_project-structure.md`.

- **La curation vit hors du dépôt.** Les anciens dossiers de curation de
  `dev/` sont archivés dans un dossier de curation local, comme trace du
  travail passé. Ce dépôt est public, et ces dossiers contenaient des
  brouillons et des données de déposants.
- **Aucune donnée de jeu dans le dépôt**, ni de curation ni d'essai.
- **Le skill de curation reste assez indépendant du paquet** : il s'en sert
  quand c'est utile (API, génération du README, scripts R réutilisables), et
  peut curer sans lui.
- **Les README générés restent génériques.**
- **Licence GPL-3.**
- **Journal des versions : `CHANGELOG.md`**, au format Keep a Changelog.
- **`test.R` est le script de pilotage du paquet**, pas des tests. Il devient
  `dev/main.R` et garde sa forme (un vecteur `to_do`, un bloc par action),
  une manière humaine de manier le paquet qui vaut d'être gardée.
- **La conversion des tableaux vers un CSV propre pour Dataverse** est l'une
  des étapes les plus récurrentes de la curation : elle doit retrouver un
  équivalent propre à un moment.
