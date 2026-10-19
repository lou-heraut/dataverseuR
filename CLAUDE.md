# dataverseuR

Paquet R qui parle à l'API Dataverse (Recherche Data Gouv d'abord), écrit les
métadonnées d'un jeu depuis un YAML simple et génère un README depuis un
modèle. Les repères du projet sont dans `dev/decisions.md`.

## Travailler ici

- Le paquet est en anglais (code, roxygen, README, messages en ASCII) ; les
  fichiers du projet et les commits sont en français.
- `man/` et `NAMESPACE` sont générés par roxygen. Régénérer avec une autre
  version de roxygen2 que celle du `DESCRIPTION` (`RoxygenNote`) touche
  d'autres fichiers : ne commiter que ce qui suit la modification.
- `dev/main.R` est le script de pilotage du paquet (un vecteur `to_do`, un bloc
  par action) ; il se lance depuis la racine, avec `devtools::load_all()`.
- À la racine, deux fichiers d'environnement non versionnés : `.env-demo` pour
  l'instance de démonstration, `.env-entrepot` pour l'entrepôt en production.

## Ce qu'il ne faut pas casser

- L'intégration continue (`R CMD check --as-cran`) échoue au moindre
  avertissement : un check en local avant de pousser.
- `generate_metadata_json()` et `convert_metadata_to_yml()` redonnent à
  l'identique les jeux d'essai de `tests/testthat/fixtures/`.
- Le modèle `inst/templates/README_template_en.txt` sert aussi hors de ce
  dépôt : ses champs entre accolades sont une interface.
- `.Rbuildignore` : des motifs ancrés (`^…$`), un motif libre a déjà retiré un
  modèle de `inst/` du paquet. Pas de fichier caché dans `inst/` (note du
  check).
- La version vit dans `DESCRIPTION` ; `codemeta.json` et `CITATION.cff` la
  reprennent à la main à chaque version.
