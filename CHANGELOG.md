# Journal des modifications

Format [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/), numéros de
version [SemVer](https://semver.org/lang/fr/).

## Non publié

### Ajouté

- `get_datasets_citation()` : la citation formatée d'un ou plusieurs jeux.
- `convert_DOI_to_ID()` : l'identifiant numérique interne d'un jeu.
- `move_datasets()` : déplace un jeu vers une autre collection (comptes
  autorisés seulement).
- `create_datasets_README()` : génère un README depuis les métadonnées en ligne
  et le modèle RDG x RiverLy (`inst/templates/README_template_en.txt`).
- `clean_datasets_files()` : convertit en CSV les fichiers tabulaires d'un jeu
  téléchargé, avec `ASHE::convert_tibble()`.

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
