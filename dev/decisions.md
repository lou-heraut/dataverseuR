# Décisions

Les repères qui cadrent le projet, avec leur raison. Ils évoluent avec le
travail ; git garde l'historique.

## 2026-10-19, après l'audit de structure

- La curation se fait hors de ce dépôt. Les anciens dossiers `dev/dataverse_*`
  sont archivés dans le dossier de curation local, comme trace du travail
  passé. Le dépôt est public, et ces dossiers mêlaient brouillons, données de
  déposants et plusieurs gigaoctets de fichiers.
- Pas de données de jeux dans le dépôt, ni de curation ni d'essai.
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

## 2026-10-19, en reprenant les tests

- Les jeux d'essai des tests sont fabriqués pour le test : petits, un par cas,
  jamais tirés d'un jeu en ligne. Les trois fichiers de métadonnées rangés dans
  `tests/testthat/fixtures/` pendant l'audit venaient d'un jeu réel ; c'étaient
  des brouillons de développement, remplacés par un YAML inventé. Un test
  produit à partir de la sortie du code ne dit que « rien n'a bougé », pas
  « c'est juste ».
- Le YAML des métadonnées existe pour que des humains les écrivent et les
  maintiennent simplement, sans les accolades et les crochets du JSON. Une
  modification ne doit pas alourdir son format. Les raccourcis qui allègent
  l'écriture se gardent : une valeur seule sans tiret de liste, un sous-champ
  écrit seul (`country: France`), des valeurs sans guillemets. Une erreur
  d'écriture s'arrête sur un message qui dit quoi corriger, plutôt que d'être
  perdue en silence.
- Les essais qui écrivent se font sur l'instance de démonstration
  (https://demo.recherche.data.gouv.fr, `.env-demo`), et nettoient derrière
  eux. Un jeu de l'entrepôt ne sert qu'en lecture : MAKAHO, dont Lou est
  l'auteur, ou un grand jeu public riche en métadonnées.
