# Feuille de route

Ce qui reste à faire. Le plan vient de l'audit du 2026-10-19
(`dev/audits/2026-10-19_project-structure.md`), les repères du projet sont dans
`dev/decisions.md`, ce qui est fait dans `CHANGELOG.md`.

## Prochaines étapes

1. **Les chemins.** Leur gestion n'est pas toujours bonne : les fonctions de
   téléchargement, de nettoyage et de README déduisent leurs dossiers du DOI
   (`{doi}/`, `{doi}_cleaned/`), et le champ `Path:` du README écrit le chemin
   local. Trouver quelque chose de plus simple et plus propre.
2. **Petits défauts.**
   - « directoryies » dans `get_info_dir()`.
   - L'argument inutilisé `dataverse` de `modify_datasets()`.
   - La valeur de retour de `get_datasets_metadata()`, qui ne correspond pas à
     sa documentation.
   - `dotenv` est déclaré dans `Imports` sans que le paquet l'appelle (la
     seule note du check) ; le README demande aux utilisateurs de s'en servir.
   - Le champ `Title` répète le nom du paquet (contrôle CRAN).
   - Les fichiers d'un brouillon n'ont pas de DOI. `delete_all_datasets_files()`
     annonce alors « file  deleted », sans nom ni identifiant.

## Questions ouvertes

- **La conversion vers un CSV propre.** `clean_datasets_files()` n'ajoute
  qu'une boucle sur un dossier autour de `ASHE::convert_tibble()`, qui lit avec
  `read.csv` (types devinés, dates converties) puis réécrit
  (`ASHE/R/read_write.R`) : les valeurs peuvent changer en route (zéros de tête
  d'un code, écriture des décimales, dates ambiguës). Par défaut, elle
  convertit aussi un simple fichier `.txt` en `.csv`, ce qui a été constaté sur
  la démo le 2026-10-20. À voir avec un audit d'ASHE.
- **Aligner les données sur des vocabulaires contrôlés pendant la curation**
  (unités QUDT ou UCUM, par exemple). Horizon lointain, et peut-être pas dans
  dataverseuR : le sujet dépasse le paquet. Les premiers essais sont dans le
  dossier parent du dépôt (`QUDT/`, `UCUM/`). En suspens.

## Plus tard

- Passer de `httr` (superseded) à `httr2`.
- Mettre à jour `actions/checkout@v4` dans `.github/workflows/`. Node.js 20
  est déprécié sur GitHub Actions, comme le signale une annotation de
  l'intégration continue du 2026-10-20.
- Des tests d'API avec `vcr`, sans jeton dans les enregistrements.
- Mettre à jour la documentation : les liens vers le guide Dataverse (5.3
  aujourd'hui, 6.x courant), le lien mort vers
  `dataverseuR_toolbox/Explore2/post_hydrological_projection.R` (neuf fichiers
  `man/`), et le README (exemple de `create_datasets()` obsolète, fonctions
  récentes absentes, badge « stable »).
- Remplacer un fichier d'un brouillon par le point d'accès de remplacement de
  l'API.
