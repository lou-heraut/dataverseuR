# Décisions

Les repères qui cadrent le projet, avec leur raison. Ils évoluent avec le
travail ; git garde l'historique.

## 2026-10-19, après l'audit de structure

- La curation se fait hors de ce dépôt. Les anciens dossiers `dev/dataverse_*`
  sont archivés dans le dossier de curation local, comme trace du travail
  passé. Le dépôt est public, et ces dossiers mêlaient brouillons, données de
  déposants et plusieurs gigaoctets de fichiers.
- Pas de données de jeux dans le dépôt, ni de curation ni d'essai. Les jeux
  d'essai des tests sont des fichiers de métadonnées.
- dataverseuR est un outil dont le skill de curation peut se servir, pas une
  dépendance : le skill sait curer sans lui. Le paquet n'a donc pas à épouser
  l'organisation du skill ; ce qui compte, c'est que ses fonctions s'utilisent
  simplement depuis des scripts (API, README, scripts de suivi qu'on peut
  donner aux déposants).
- Les README générés sont génériques : rien de la machine qui les produit.
- GPL-3, comme ASHE. L'AGPL n'apporte rien à un paquet R utilisé en local.
- `CHANGELOG.md` au format Keep a Changelog, comme les autres projets.
- `dev/main.R` est le script de pilotage du paquet : un vecteur `to_do`, un
  bloc par action. C'est une manière humaine de s'en servir et une trace de
  l'usage réel ; sa forme se garde, et peut servir de modèle aux scripts
  d'usage écrits pour d'autres.
- Convertir des tableaux mal formés en CSV propre pour Dataverse est l'une des
  étapes les plus fréquentes de la curation, et mérite un outil propre.
  L'actuel, `ASHE::convert_tibble()`, peut changer des valeurs en les relisant :
  à garder en tête tant qu'il n'est pas repris.
