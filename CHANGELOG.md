# Journal des modifications

Format [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/), numéros de
version [SemVer](https://semver.org/lang/fr/).

## Non publié

### Corrigé

- `generate_metadata_json()` et `convert_metadata_to_yml()` sont réécrites et
  traduisent directement le YAML en JSON et inversement. Les défauts corrigés :
  - Chaque sous-champ reste avec son élément. Avant, un sous-champ absent du
    premier élément glissait sur l'élément voisin, et un sous-champ présent une
    seule fois était perdu, par exemple l'adresse d'un mot-clé.
  - Un champ simple à plusieurs valeurs (deux langues, deux types de données)
    ne disparaît plus.
  - Un YAML où aucun nom de champ ne se répète ne fait plus planter la
    conversion.
  - Le fichier de sortie garde le bon chemin quand un dossier contient « yml »
    ou « json » dans son nom.

### Modifié

- Les valeurs du YAML sont lues comme elles sont écrites : `1.10` reste `1.10`
  et `no` reste `no`. Avant, elles devenaient 1.1 et FALSE, ou faisaient
  planter la conversion.
- Une erreur d'écriture dans le YAML arrête la conversion avec un message qui
  dit quoi corriger, au lieu d'être perdue ou rattachée au hasard. C'est le cas
  d'un champ ou d'un sous-champ inconnu, d'un sous-champ écrit hors de son
  élément, ou d'un champ composé écrit comme une simple valeur. Un YAML qui
  passait peut donc maintenant s'arrêter.
- Le paquet ne dépend plus de `stringr` ni de `tibble`.

### Ajouté

- Un champ composé à un seul élément peut s'écrire sans tiret de liste.
- `convert_metadata_to_yml()` lit aussi le JSON écrit par
  `generate_metadata_json()`.
- Des tests (testthat), sur des métadonnées inventées.

## [0.2.0] - 2026-10-19

### Ajouté

- `get_datasets_citation()` : la citation formatée d'un ou plusieurs jeux.
- `convert_DOI_to_ID()` : l'identifiant numérique interne d'un jeu.
- `move_datasets()` : déplace un jeu vers une autre collection (comptes
  autorisés seulement).
- `create_datasets_README()` : génère un README depuis les métadonnées en ligne
  et le modèle RDG x RiverLy (`inst/templates/README_template_en.txt`).
- `clean_datasets_files()` : convertit en CSV les fichiers tabulaires d'un jeu
  téléchargé, avec `ASHE::convert_tibble()`.
- `CITATION.cff`, pour citer le paquet.

### Modifié

- `download_datasets_files()` prend des DOI de jeux et télécharge tous leurs
  fichiers, un dossier par jeu. L'ancien comportement (des fichiers choisis par
  leur DOI) devient `download_some_datasets_files()`.
- ASHE n'est plus attaché avec le paquet (passé de `Depends` à `Imports`) :
  appeler ses fonctions avec `ASHE::`.
- Licence GPL (>= 3) partout : le fichier `LICENSE` contenait le texte de
  l'AGPL, remplacé par celui de la GPL dans `LICENSE.md`.
- Le dépôt GitHub s'appelle désormais `lou-heraut/dataverseuR`.
- `create_dotenv()` crée directement le fichier `.env` à remplir, au lieu d'un
  `dist.env` à renommer, et laisse intact un `.env` existant (sauf
  `overwrite=TRUE`). Son modèle dans le paquet s'appelle `env.example`.

### Corrigé

- `create_dotenv()` : son modèle manquait au paquet installé, exclu par un
  motif trop large de `.Rbuildignore`.
- `delete_all_datasets_files()` appelait des fonctions qui avaient été
  renommées.
- La documentation de quatre fonctions exportées manquait au paquet.

## [0.1.1] - 2025-10-13

Première version notée dans ce journal ; ce qui précède est dans l'historique
git.
