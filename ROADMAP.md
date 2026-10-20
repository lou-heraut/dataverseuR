# Feuille de route

Ce qui reste à faire. Le plan vient de l'audit du 2026-10-19
(`dev/audits/2026-10-19_project-structure.md`), les repères du projet sont dans
`dev/decisions.md`, ce qui est fait dans `CHANGELOG.md`.

## Prochaines étapes

1. **Reprendre `dev/main.R`.** Garder sa forme (`to_do`, un bloc par action).
   Aujourd'hui, 4 blocs sur 10 appellent des fonctions disparues, 2 autres des
   variables qu'aucun bloc ne définit, et il reste un chemin absolu vers ASHE
   et des `stop()` de travail. Le script charge `.env-entrepot` (la
   production) par défaut, et ses blocs visent des jeux réels.
2. **Les chemins.** Leur gestion n'est pas toujours bonne : les fonctions de
   téléchargement, de nettoyage et de README déduisent leurs dossiers du DOI
   (`{doi}/`, `{doi}_cleaned/`), et le champ `Path:` du README écrit le chemin
   local. Trouver quelque chose de plus simple et plus propre.
3. **Petits défauts.**
   - « directoryies » dans `get_info_dir()`.
   - L'argument inutilisé `dataverse` de `modify_datasets()`.
   - La valeur de retour de `get_datasets_metadata()`, qui ne correspond pas à
     sa documentation.
   - `dotenv` est déclaré dans `Imports` sans que le paquet l'appelle (la
     seule note du check) ; le README demande aux utilisateurs de s'en servir.
   - Le champ `Title` répète le nom du paquet (contrôle CRAN).

## Questions ouvertes

- **La conversion vers un CSV propre.** `clean_datasets_files()` n'ajoute
  qu'une boucle sur un dossier autour de `ASHE::convert_tibble()`, qui lit avec
  `read.csv` (types devinés, dates converties) puis réécrit
  (`ASHE/R/read_write.R`) : les valeurs peuvent changer en route (zéros de tête
  d'un code, écriture des décimales, dates ambiguës). À voir avec un audit
  d'ASHE.
- **Aligner les données sur des vocabulaires contrôlés pendant la curation**
  (unités QUDT ou UCUM, par exemple). Horizon lointain, et peut-être pas dans
  dataverseuR : le sujet dépasse le paquet. Les premiers essais sont dans le
  dossier parent du dépôt (`QUDT/`, `UCUM/`). En suspens.

## Plus tard

- Passer de `httr` (superseded) à `httr2`.
- Des tests d'API avec `vcr`, sans jeton dans les enregistrements.
- Mettre à jour la documentation : les liens vers le guide Dataverse (5.3
  aujourd'hui, 6.x courant), le lien mort vers
  `dataverseuR_toolbox/Explore2/post_hydrological_projection.R` (neuf fichiers
  `man/`), et le README (exemple de `create_datasets()` obsolète, fonctions
  récentes absentes, badge « stable »).
- Remplacer un fichier d'un brouillon par le point d'accès de remplacement de
  l'API.
