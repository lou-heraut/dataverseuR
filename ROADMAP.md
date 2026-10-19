# Feuille de route

Ce qui reste à faire. Le plan vient de l'audit du 2026-10-19
(`dev/audits/2026-10-19_project-structure.md`), les choix déjà faits sont dans
`dev/decisions.md`.

## Prochaines étapes

1. **Ranger la racine et `dev/`.**

   ```
   Fichier                               Destination
   metadata.yml, metadata.json           tests/testthat/fixtures/ (aller-retour YAML -> JSON)
   tmp.json ou metadata_dl.json          tests/testthat/fixtures/ (JSON téléchargé), l'autre supprimé
   qudt-unit-3.1.9.ttl                   supprimé (copie identique de dev/QUDT/)
   JP_datasets.csv                       supprimé (sortie de search_datasets)
   inst/extdata/metadata_cut*.json       supprimés (fragments JSON non valides)
   py/api.py                             dataverseuR_toolbox (exemple d'usage en Python)
   dev/QUDT/, dev/UCUM/                  dev/units/ : script et CSV final suivis, .ttl et
                                         CSV intermédiaires ignorés (ils se régénèrent)
   dev/old/, dev/jdd_complet.json        supprimés (l'historique les garde)
   ```

2. **Fermer les fuites du build.** Ajouter à `.Rbuildignore` `^dev$`, `^py$`,
   `^Makefile$`, `^codemeta\.json$`, `^CODE_OF_CONDUCT\.md$`, `^CLAUDE\.md$`,
   `^ROADMAP\.md$`, `^CHANGELOG\.md$`, `^CITATION\.cff$`.
3. **Remettre le check au vert.** Commiter les `man/*.Rd` manquants, passer le
   message de `R/api.R:402` en anglais ASCII, déclarer `fs` et `utils`, sortir
   `ASHE` de `Depends`, régler les variables globales et l'argument
   `replace_draft`, remplacer le texte de `LICENSE` par la GPL-3 et corriger
   `codemeta.json`. Cible : zéro avertissement en local, puis sur GitHub.
4. **Poser les fichiers du projet.** Un `CLAUDE.md` court, `CHANGELOG.md`,
   `CITATION.cff` ; la version vit dans `DESCRIPTION`, `codemeta.json` la
   reprend. Une fois le check vert, publier 0.2.0 avec le tag `v0.2.0`.
5. **Premiers tests.** `sanitize_doi()`, `format_yml()`, l'aller-retour des
   métadonnées sur les jeux d'essai de l'étape 1.
6. **Reprendre le script de pilotage : `test.R` devient `dev/main.R`.** Garder
   sa forme (`to_do`, un bloc par action), rendre chaque bloc autonome (ses
   entrées en tête de bloc), retirer les chemins absolus et les `stop()` de
   travail, mettre à jour les noms de fonctions (4 blocs sur 10 appellent des
   fonctions disparues, 2 autres des variables qu'aucun bloc ne définit).
   Ensuite, une version pour les utilisateurs dans `dataverseuR_toolbox`.
7. **Aligner sur le skill `curation-rdg`.** Les fonctions de téléchargement, de
   nettoyage et de README reçoivent leurs dossiers en arguments au lieu de les
   dériver du DOI (`{doi}/`, `{doi}_cleaned/`). Le README généré reste
   générique : le champ `Path:` donne un chemin relatif au jeu, plus le chemin
   local ; « directoryies » se corrige. Retirer l'argument inutilisé
   `dataverse` de `modify_datasets()`, et faire renvoyer à
   `get_datasets_metadata()` ce que sa documentation annonce.

## Questions ouvertes

- **Une conversion fidèle vers un CSV propre.** C'est une étape centrale de la
  curation (voir `dev/decisions.md`). `clean_datasets_files()` n'ajoute qu'une
  boucle sur un dossier autour de `ASHE::convert_tibble()`, qui lit avec
  `read.csv` (types devinés, dates converties) puis réécrit
  (`ASHE/R/read_write.R`) : les valeurs peuvent changer en route (zéros de tête
  d'un code, écriture des décimales, dates ambiguës). En attendant, la fonction
  reste, avec `ASHE` en `Suggests`. À trancher avec un audit d'ASHE, qui n'est
  pas un préalable au reste : où vit la conversion fidèle, et ce que devient
  `clean_datasets_files()`.

## Plus tard

- Passer de `httr` (superseded) à `httr2`.
- Des tests d'API avec `vcr`, sans jeton dans les enregistrements.
- Mettre à jour les liens vers le guide Dataverse (5.3 aujourd'hui, 6.x
  courant) et le README (exemple de `create_datasets()` obsolète, fonctions
  récentes absentes, badge « stable »).
- Remplacer un fichier d'un brouillon par le point d'accès de remplacement de
  l'API.
- Les unités QUDT/UCUM dans le README généré.
