# Feuille de route

Ce qui reste à faire. Le plan vient de l'audit du 2026-10-19
(`dev/audits/2026-10-19_project-structure.md`), les choix déjà faits sont dans
`dev/decisions.md`.

## Prochaines étapes

1. **Fermer les fuites du build.** Ajouter à `.Rbuildignore` les fichiers du
   projet qui ne sont pas du paquet : `Makefile`, `codemeta.json`,
   `CODE_OF_CONDUCT.md`, `ROADMAP.md`, puis `CLAUDE.md`, `CHANGELOG.md` et
   `CITATION.cff` quand ils existeront.
2. **Remettre le check au vert.** Passer le message de `R/api.R:402` en anglais
   ASCII, déclarer `fs` et `utils`, sortir `ASHE` de `Depends`, régler les
   variables globales et l'argument `replace_draft`, remplacer le texte de
   `LICENSE` par la GPL-3 et corriger `codemeta.json`. Cible : zéro
   avertissement en local, puis sur GitHub.
3. **Poser les fichiers du projet.** Un `CLAUDE.md` court, `CHANGELOG.md`,
   `CITATION.cff` ; la version vit dans `DESCRIPTION`, `codemeta.json` la
   reprend. Une fois le check vert, publier 0.2.0 avec le tag `v0.2.0`.
4. **Premiers tests.** `sanitize_doi()`, `format_yml()`, l'aller-retour des
   métadonnées sur les jeux d'essai de `tests/testthat/fixtures/`.
5. **Reprendre `dev/main.R`.** Garder sa forme (`to_do`, un bloc par action).
   Aujourd'hui, 4 blocs sur 10 appellent des fonctions disparues, 2 autres des
   variables qu'aucun bloc ne définit, et il reste un chemin absolu vers ASHE
   et des `stop()` de travail.
6. **Les chemins.** Leur gestion n'est pas toujours bonne : les fonctions de
   téléchargement, de nettoyage et de README déduisent leurs dossiers du DOI
   (`{doi}/`, `{doi}_cleaned/`), et le champ `Path:` du README écrit le chemin
   local. Trouver quelque chose de plus simple et plus propre.
7. **Petits défauts.** « directoryies » dans `get_info_dir()`, l'argument
   inutilisé `dataverse` de `modify_datasets()`, la valeur de retour de
   `get_datasets_metadata()` qui ne correspond pas à sa documentation.

## Questions ouvertes

- **La conversion vers un CSV propre.** `clean_datasets_files()` n'ajoute
  qu'une boucle sur un dossier autour de `ASHE::convert_tibble()`, qui lit avec
  `read.csv` (types devinés, dates converties) puis réécrit
  (`ASHE/R/read_write.R`) : les valeurs peuvent changer en route (zéros de tête
  d'un code, écriture des décimales, dates ambiguës). À voir avec un audit
  d'ASHE.

## Plus tard

- Passer de `httr` (superseded) à `httr2`.
- Des tests d'API avec `vcr`, sans jeton dans les enregistrements.
- Mettre à jour les liens vers le guide Dataverse (5.3 aujourd'hui, 6.x
  courant) et le README (exemple de `create_datasets()` obsolète, fonctions
  récentes absentes, badge « stable »).
- Remplacer un fichier d'un brouillon par le point d'accès de remplacement de
  l'API.
