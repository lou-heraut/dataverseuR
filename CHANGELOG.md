# Journal des modifications

Format [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/), numéros de
version [SemVer](https://semver.org/lang/fr/).

## Non publié

## [0.4.0] - 2026-10-20

### Modifié

- Les fonctions sur les fichiers reçoivent leurs dossiers au lieu de les
  déduire du DOI :
  - `download_datasets_files(dataset_DOI, dirpath)` : `dirpath` donne un
    dossier par jeu, par défaut le DOI assaini dans le dossier courant. Les
    fichiers gardent leur sous-dossier dans le jeu. Avant, ils allaient tous à
    plat dans `dataverse_files/doi_…/`.
  - `clean_datasets_files(input_dir, output_dir)` ne prend plus de DOI. Il
    convertit les tableaux d'un dossier vers un autre, sous-dossiers compris.
    Avant, il lisait `doi_…/` et écrivait dans `doi_…_cleaned/`.
  - `create_datasets_README(dataset_DOI, dirpath, README_path)` décrit le
    dossier donné et écrit le README à l'endroit demandé, par défaut dans ce
    dossier. Son champ `Path:` donne le dossier du fichier dans le jeu (`.`,
    `./data`), et non plus le chemin local.

### Corrigé

- Le README compte les dossiers de son arborescence (« 1 directory,
  2 files »). Avant, il annonçait toujours « 0 directoryies ».
- Le README ne se décrit plus lui-même quand il est régénéré dans le dossier
  qu'il décrit. Un dossier vide ne fait plus échouer sa génération.
- `modify_datasets()`, `delete_datasets()` et `delete_all_datasets_files()`
  attendent aussi que le jeu ne soit plus verrouillé. Sur l'instance de
  démonstration, une modification lancée juste après l'ajout d'un tableau
  échouait en erreur 500 (4 fois sur 4). Une fois, elle a laissé le jeu
  verrouillé pour de bon, au point de ne plus pouvoir le supprimer.

## [0.3.1] - 2026-10-20

### Corrigé

- `add_datasets_files()` attend, avant chaque envoi, que le jeu ne soit plus
  verrouillé. Juste après l'ajout d'un tableau, Dataverse le verrouille le
  temps de le convertir, et refusait le fichier suivant.
  `publish_datasets()` attend de la même façon.
- `add_datasets_files()` n'annonce plus « added » pour un fichier refusé.

## [0.3.0] - 2026-10-20

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
