# Audit du 2026-10-19 : structure du dépôt et séparation de la curation

## Le sujet

Sortir de dataverseuR les dossiers de curation qui vivent dans `dev/`, ranger
les fichiers qui traînent, et clarifier le rôle du paquet face au skill
`curation-rdg` en construction, qui doit s'appuyer sur lui pour lire, télécharger
et modifier des jeux Recherche Data Gouv (RDG). Le but : repartir sur une base
de développement saine.

Lu pour cet audit : le code du paquet et son historique git, un `R CMD check
--as-cran` sur une copie propre du dernier commit (`1136c8e`), l'état de
l'intégration continue par l'API publique de GitHub, le dépôt du skill
(`claude-code_project/claude-code-curation-rdg`), le dépôt
`dataverseuR_toolbox`, et les sources en ligne listées en fin de fichier.

## Constats

### 1. Le dépôt mélange le paquet, son usage et des brouillons

Inventaire au 2026-10-19 (tailles mesurées par `du`, suivi par `git ls-files`) :

```
Emplacement                          Taille    Suivi git  Nature
R/, man/, inst/, DESCRIPTION, ...    ~0,3 Mo   oui        le paquet
dev/dataverse_hevin/                 7,4 Go    non        curation DNZKIK, dont 465 Mo d'environnement Python
dev/dataverse_data_guillaume/        1,7 Go    non        curation EITAMZ
dev/dataverse_data_lulc/             115 Mo    non        curation Y6IADU
dev/dataverse_data_etienne/          14 Mo     non        curation VOYD57
dev/dataverse_data_* (6 autres)      < 1 Mo    non        curations TGYZ8L, FLBIX4, P0RECJ, X0AVL1, DP0DQH, XFO4GY
dev/dataverse_files_remy/            0,9 Mo    non        prototype du README automatique, sur un jeu réel
dev/dataverse_manual_example/        0,4 Mo    oui        prototype du README automatique (jeu 5EBITB), note UCUM
dev/QUDT/, dev/UCUM/                 8,3 Mo    en partie  exploration des vocabulaires d'unités
dev/old/, dev/jdd_complet.json       0,1 Mo    oui        ancien format R des métadonnées, exemple JSON complet
racine : metadata.json, metadata_dl.json, metadata.yml, tmp.json, JP_datasets.csv,
         qudt-unit-3.1.9.ttl (copie identique de dev/QUDT/), test.R, .Rhistory
inst/extdata/metadata_cut*.json      2 Ko      non        fragments JSON non valides (2025-10-11)
py/api.py                            3 Ko      oui        script Python d'envoi de fichiers, autonome
```

Les douze dossiers de curation pèsent environ 9,2 Go. Ils suivent tous la même
forme : un dossier brut `doi_…/`, un dossier `doi_…_cleaned/`, parfois des
scripts et des notes. `dev/dataverse_hevin/` a déjà son `CLAUDE.md`, son
`ROADMAP.md` et son `CHANGELOG.md` : c'est le précurseur du dossier par jeu que
le skill a adopté.

### 2. Construire le paquet depuis ce dossier copierait tout `dev/`

`.Rbuildignore` n'exclut que `.github`, `.env*` et `test.R`. `R CMD build`
lancé dans le dossier de travail copierait donc `dev/` (9,2 Go), `py/`, les
fichiers de la racine, `Makefile`, `codemeta.json` et `CODE_OF_CONDUCT.md`.
*R Packages* (2e éd.) présente `.Rbuildignore` comme l'outil pour retirer du
paquet construit ce qui sert au développement.

### 3. L'intégration continue échoue depuis le 15 janvier 2026

- Sur 27 exécutions, 8 ont réussi ; la dernière réussite date du 2026-01-14
  (`156aaa9`), les cinq suivantes échouent sur les cinq systèmes (API GitHub,
  `actions/runs`).
- Le check local sur le dernier commit donne 3 avertissements et 3 notes :
  quatre fonctions exportées sans documentation, une chaîne non ASCII dans
  `R/api.R:402` (« non trouvée »), la licence (constat 6), `fs` utilisé sans
  être déclaré, `ASHE` à la fois dans `Depends` et `Imports`, `dotenv` déclaré
  mais inutilisé, des variables globales et `capture.output`, `glob2rx` non
  importés, et une correspondance partielle d'argument (`replace_draft` pour
  `replace_draft_version`, `R/curation.R`).
- Cause probable : le commit `324068d` (2026-01-15) ajoute
  `clean_datasets_files()`, `create_datasets_README()` et leurs voisines avec
  leur roxygen, mais les fichiers `man/*.Rd` correspondants n'ont jamais été
  commités (ils sont dans `git status`, non suivis). Or l'action
  `check-r-package` échoue dès un avertissement (`error-on` vaut `"warning"`
  par défaut, documentation de r-lib/actions).
- Le README affiche le badge « Lifecycle: stable », sans tests et avec
  l'intégration continue en échec.

### 4. Deux conventions de dossier pour un même jeu

- dataverseuR dérive les chemins au lieu de les recevoir :
  `download_datasets_files()` écrit dans `{dirpath}/{doi}/`,
  `clean_datasets_files()` lit là et écrit dans `{dirpath}/{doi}_cleaned/`,
  `create_datasets_README()` écrit dans ce même `_cleaned/` (`R/api.R`,
  `R/curation.R`).
- Le skill a choisi le 2026-10-17 un dossier par jeu avec `original/`,
  `cleaned/`, `metadata/`, `scripts/` et `curation.md` (`SKILL.md`), nommé par
  `sanitize_doi()` « pour que les deux outils se rejoignent plus tard »
  (`dev/decisions.md` du skill).
- Les fonctions du paquet ne peuvent donc pas écrire dans le dossier du skill
  sans changement. `download_some_datasets_files(file_DOI, save_paths)` prend
  déjà des chemins explicites : c'est le modèle à suivre.
- Deux défauts relevés par le skill sont confirmés dans le code :
  `get_info_dir()` écrit « directoryies » (`R/curation.R:62-64`), et le champ
  `Path:` du README reprend le chemin local (`dirname(path)`,
  `R/curation.R:410`).

### 5. Ce dont le skill a besoin, et ce que le paquet offre

D'après le déroulé de `SKILL.md`, confronté au code :

- Lire les métadonnées : `get_datasets_metadata()` puis
  `convert_metadata_to_yml()`. Fonctionne ; la fonction écrit un fichier et ne
  renvoie rien, alors que sa documentation annonce une liste.
- Lister noms, formats et tailles avant de télécharger :
  `list_datasets_files()`, avec la colonne `filesize`. Fonctionne.
- Télécharger dans `original/` : `download_datasets_files()` impose
  `{dirpath}/{doi}/` ; `download_some_datasets_files()` convient.
- Enregistrer l'état avant chaque écriture dans `metadata/` :
  `get_datasets_metadata()` avec un chemin daté par l'appelant. Fonctionne.
- Écrire des métadonnées : `generate_metadata_json()` puis
  `modify_datasets()`. Fonctionne ; l'argument `dataverse` de
  `modify_datasets()` est obligatoire et jamais utilisé.
- Remplacer un fichier d'un brouillon : rien. Il faut aujourd'hui supprimer
  puis ajouter ; l'API native a un point d'accès de remplacement.
- Générer le README : `create_datasets_README()`, avec les limites du
  constat 4.
- Nettoyer les fichiers : `clean_datasets_files()`, qui convertit en masse avec
  `ASHE::convert_tibble()` en devinant séparateur et encodage. Le skill demande
  autre chose : chaque correction passe par un script de `scripts/`, relisible,
  qui vérifie que les valeurs n'ont pas changé.

### 6. Les métadonnées du paquet se contredisent

- Licence : `DESCRIPTION` dit `GPL-3 + file LICENSE` depuis le premier commit,
  les en-têtes des fichiers R parlent de GPL (avec la coquille « xGeneral »),
  mais le fichier `LICENSE` est le texte de l'AGPL v3 et `codemeta.json` dit
  `AGPL-3.0-or-later`. Le check le relève.
- Version : `DESCRIPTION` dit 0.1.1 (2025-10-13), `codemeta.json` 0.1.0
  (2025-10-08). Aucun tag git, ni `NEWS.md` ni `CHANGELOG.md`.
- Dépendances : `ASHE` (sur GitHub seulement, via `Remotes`) est dans
  `Depends` et `Imports`, alors que seules deux fonctions de curation s'en
  servent (`convert_tibble`, `read_tibble`).
- Ni `CITATION.cff`, ni `ROADMAP.md`, ni `CLAUDE.md`.
- Le README n'a pas suivi le code : l'exemple de `create_datasets()` utilise
  l'ancienne API (`source(metadata_path)`, `generate_metadata()`,
  `metadata_path=`), et les fonctions ajoutées depuis octobre 2025 (citation,
  curation, déplacement, renommage) n'y figurent pas.

### 7. Rien n'est testé, mais les jeux d'essai existent déjà

- Pas de dossier `tests/`. `test.R` est un brouillon de session qui appelle
  cinq fonctions sous des noms qui n'existent plus (`add_dataset_files`,
  `publish_dataset`, `modify_dataset_metadata`…).
- Les fichiers qui traînent à la racine sont des entrées et sorties réelles de
  la conversion YAML ↔ JSON : `metadata.yml` et `metadata.json` (format
  `datasetVersion`, pour créer ou modifier), `tmp.json` et `metadata_dl.json`
  (format `latestVersion`, tel que téléchargé). Ce sont des jeux d'essai tout
  prêts pour la partie qui fait la valeur du paquet.
- Une bonne part du code est testable sans réseau : `sanitize_doi()`,
  `cut_line()` et `format_yml()`, l'aller-retour
  `generate_metadata_json()` / `convert_metadata_to_yml()`, le remplissage du
  modèle de README. Pour les appels à l'API, rOpenSci propose `vcr`, qui
  enregistre les réponses une fois et les rejoue, avec un filtre pour ne pas
  écrire le jeton dans les enregistrements.

### 8. La pile technique et ce qui existe ailleurs

- `httr` est déclaré « superseded » : seules les corrections nécessaires à son
  maintien sur CRAN seront faites, `httr2` est recommandé (site de httr). Pas
  urgent, mais tout le paquet en dépend.
- Le client R officiel, `dataverse` (IQSS, CRAN 0.3.16, 2025-11-05), couvre
  bien la lecture et prévient de problèmes connus sur la création de jeux.
  dataverseuR occupe une place qu'il ne prend pas : les métadonnées en YAML, les
  écritures, le README. Il comble un manque ; ce n'est pas une fausse route.
- Les liens de la documentation pointent vers le guide Dataverse 5.3 ; le guide
  courant est en 6.12.1. RDG tournait en 6.0 d'après les notes de curation de
  `dev/dataverse_hevin/CLAUDE.md` (la page `/api/info/version` de RDG est
  derrière une protection anti-robots, non vérifié ici).
- Pour brancher un paquet R sur un agent, `mcptools` (Posit, 1.0 sur CRAN en
  juillet 2026) sert des fonctions R comme outils MCP à Claude Code. Les skills
  de Claude Code peuvent aussi appeler des scripts (`${CLAUDE_SKILL_DIR}`) et
  pré-autoriser une commande par `allowed-tools`.
- La démarche de curation du skill rejoint celle du Data Curation Network
  (CURATE(D) : vérifier, comprendre, demander, enrichir, transformer, évaluer,
  documenter), qui insiste aussi sur la lecture complète avant tout contact
  avec le déposant.

### 9. Autour du dépôt

- `dataverseuR_toolbox` (public sur GitHub) porte déjà les usages du paquet par
  projet (Explore2, DRYvER, HyR, bilan HCERES), et le README y renvoie. Il a
  des modifications non commitées. Ses `.env-*` ne sont pas suivis (vérifié par
  `git ls-files`).
- `dev/dataverse_manual_example/` est suivi dans git, donc publié sur GitHub :
  des données de déposants (jeu 5EBITB) et un README nominatif. Sans
  conséquence si ce jeu est publié sur RDG ; à vérifier.
- Claude Code range les sessions par chemin (`~/.claude/projects/…`). Déplacer
  `dev/dataverse_hevin/` ou `dev/dataverse_data_darde1/` laisse leurs
  transcriptions en place, mais `claude --resume` ne les proposera plus depuis
  le nouveau dossier. Le `CLAUDE.local.md` du skill y renvoie pour le ton.

## Ce qui tient bien

- La couche API : des noms réguliers (`verbe_datasets_objet`), des fonctions
  vectorisées sur les DOI, `BASE_URL` et `API_TOKEN` lus dans l'environnement,
  une progression affichée. Le sous-ensemble couvert est cohérent.
- Le format YAML des métadonnées : lisible, avec l'aller-retour depuis le JSON
  de Dataverse et des modèles dans `inst/templates/`.
- Les secrets : `.env*` ignorés dans les deux dépôts, aucun jeton suivi,
  `py/api.py` ne contient qu'un jeton factice.
- Le modèle de README « RDG x RiverLy », repris tel quel par le skill : un bien
  commun aux deux outils.
- Les scripts écrits pendant les curations (`reorder_columns.R`,
  `convert_topage.py`) : ils lisent le texte sans convertir les nombres,
  vérifient après écriture et refusent d'écraser. C'est le modèle des
  `scripts/` du skill.
- Le partage des rôles décidé dans le dépôt du skill le 2026-10-17 :
  dataverseuR comme couche de communication avec RDG, le skill comme agent de
  curation. Cet audit le confirme.

## Décisions à prendre

### D1. Où vont les dossiers de curation

- **a.** `gestion_des_donnes_project/curation-RDG/`, créé le 17 octobre et vide.
  Local, hors de GitHub. Le `CLAUDE.local.md` du skill note que l'orthographe
  « donnes » reste à confirmer.
- **b.** `dataverseuR_toolbox` : public, alors que ces dossiers contiennent des
  brouillons et des données de déposants.
- **c.** Le dépôt du skill : il porte des consignes, pas des données.

Recommandé : **a**, en corrigeant le nom au passage si « donnees » est voulu.
S'il faut un historique, un git local qui suit `curation.md` et `scripts/` et
ignore les données.

### D2. Migrer les anciens dossiers vers la forme du skill

- **a.** Tout déplacer tel quel.
- **b.** Tout convertir en `doi_…/{original,cleaned,metadata,scripts}`.
- **c.** Convertir seulement les curations en cours (DNZKIK attend une réponse,
  FLBIX4 et P0RECJ datent du 14 octobre), et déplacer les autres telles
  quelles dans un sous-dossier d'archive.

Recommandé : **c**. Question liée, à trancher par Lou : pour les jeux publiés et
clos, garder seulement scripts et notes, les données se retéléchargeant depuis
RDG (9,2 Go en jeu). L'environnement Python de DNZKIK (465 Mo) se recrée ; noter
sa dépendance (geopandas) dans `curation.md` suffit.

### D3. Ce que dataverseuR garde de la curation

- **a.** Garder `create_datasets_README()` et `clean_datasets_files()`, en leur
  passant des chemins explicites (dossier source, dossier ou fichier de sortie)
  au lieu de les dériver du DOI.
- **b.** Sortir `R/curation.R` vers les scripts du skill ; le paquet redevient
  API et métadonnées seulement.
- **c.** Garder la génération du README, avec chemins explicites (le modèle
  appartient au paquet et sert aux deux outils), et retirer
  `clean_datasets_files()`, qui n'est qu'une boucle autour de
  `ASHE::convert_tibble()` et va contre le principe du skill (un script relu
  par jeu). `ASHE` passe alors dans `Suggests`, appelé seulement pour lire les
  colonnes du README.

Recommandé : **c**, sauf si Lou se sert de `clean_datasets_files()` en dehors
du skill ; dans ce cas, **a**. Dans tous les cas, `ASHE` sort de `Depends`.

### D4. Comment le skill appelle dataverseuR

- **a.** Claude écrit de courts scripts R dans `scripts/` qui appellent
  dataverseuR, lancés par `Rscript`. Relisibles et relançables, comme le veut
  déjà `SKILL.md`.
- **b.** Un petit point d'entrée fixe (un script avec des sous-commandes :
  métadonnées, fichiers, téléchargement, état avant écriture), pré-autorisé par
  `allowed-tools`.
- **c.** Un serveur MCP avec `mcptools`, qui expose les fonctions comme outils.

Recommandé : **a** maintenant ; **b** quand les répétitions apparaîtront, après
deux ou trois curations, comme le prévoit déjà la feuille de route du skill pour
les scripts de vérification. **c** ajoute un serveur et deux dépendances pour ce
que `Rscript` fait déjà, et les écritures resteraient de toute façon soumises à
l'accord de Lou une par une.

### D5. La licence

- **a.** GPL-3 : `DESCRIPTION` et les en-têtes le disent déjà, ASHE est en
  GPL-3. Remplacer le texte de `LICENSE` et corriger `codemeta.json`.
- **b.** AGPL-3 : le texte de `LICENSE` et `codemeta.json` le disent. Corriger
  `DESCRIPTION` et les en-têtes.

Pour un paquet R exécuté en local, la clause réseau de l'AGPL change peu de
chose. Recommandé : **a**, par cohérence avec ASHE, sauf intention contraire de
Lou au moment du choix de 2025.

### D6. Le journal des versions

La règle générale de Lou est un `CHANGELOG.md` au format Keep a Changelog. La
convention R est `NEWS.md` (`# dataverseuR 0.2.0`), que GitHub, pkgdown et la
page CRAN affichent (*R Packages*, 2e éd.). Recommandé : `NEWS.md`, avec des
sous-titres « Ajouté », « Modifié », « Corrigé » dans l'esprit de Keep a
Changelog, et une ligne dans le `CLAUDE.md` du projet pour noter l'exception.

### D7. Les fichiers déjà publiés dans l'historique

`dev/dataverse_manual_example/` (données du jeu 5EBITB) et `dev/QUDT/` (3,7 Mo
de `.ttl` téléchargé) sont dans l'historique public.

- **a.** Les retirer du suivi désormais ; l'historique les garde.
- **b.** Réécrire l'historique (`git filter-repo`) et forcer la poussée, ce qui
  casse les clones existants.

Recommandé : **a** si 5EBITB est publié ; **b** seulement s'il ne l'est pas.
Le `.git` pèse 17 Mo : la taille ne justifie pas de réécrire.

## Ce qu'on attaquerait en premier

Chaque étape est petite et se vérifie seule.

1. **Sortir la curation** (D1, D2). Déplacer les douze dossiers
   `dev/dataverse_*`. Retirer `dev/dataverse_manual_example/` du suivi ; sa
   note UCUM (`issue.txt`) rejoint l'exploration des unités. Seul `test.R`
   pointe vers ces dossiers (`dev/dataverse_data_etienne`).
2. **Ranger la racine et `dev/`.**

   ```
   Fichier                               Destination proposée
   metadata.yml, metadata.json           tests/testthat/fixtures/ (aller-retour YAML -> JSON)
   tmp.json ou metadata_dl.json          tests/testthat/fixtures/ (JSON téléchargé), l'autre supprimé
   qudt-unit-3.1.9.ttl                   supprimé (copie identique de dev/QUDT/)
   JP_datasets.csv                       supprimé ou dataverseuR_toolbox (sortie de search_datasets)
   inst/extdata/metadata_cut*.json       supprimés, sauf souvenir contraire de Lou
   test.R                                dev/manual_checks.R, remis à jour, contre l'instance démo
   py/api.py                             dataverseuR_toolbox (exemple d'usage en Python)
   dev/QUDT/, dev/UCUM/                  dev/units/ : script et CSV final suivis, .ttl et CSV
                                         intermédiaires ignorés (ils se régénèrent)
   dev/old/, dev/jdd_complet.json        supprimés (l'historique les garde) ou fixture pour jdd
   ```

3. **Fermer les fuites du build.** Ajouter à `.Rbuildignore` `^dev$`, `^py$`,
   `^Makefile$`, `^codemeta\.json$`, `^CODE_OF_CONDUCT\.md$`, et les fichiers de
   projet à venir (`CLAUDE.md`, `ROADMAP.md`, `CITATION.cff`). Ajouter
   `!.env.example` au `.gitignore` si un exemple doit être suivi : le motif
   `.env*` l'ignorerait.
4. **Remettre le check au vert.** Commiter les `man/*.Rd`, passer le message de
   `R/api.R:402` en anglais ASCII, déclarer `fs` et `utils`, régler `ASHE`
   (D3), les variables globales, la licence (D5) et l'argument
   `replace_draft`. Cible : zéro avertissement en local, puis sur GitHub.
5. **Poser les fichiers du projet.** Un `CLAUDE.md` court, un `ROADMAP.md` tiré
   de cet audit, `NEWS.md` (D6), `CITATION.cff` ; la version vit dans
   `DESCRIPTION` et `codemeta.json` la reprend. Une fois le check vert, publier
   0.2.0 avec un tag : les fonctions ajoutées depuis 0.1.1 (citation, curation,
   déplacement, conversion DOI vers identifiant) le justifient.
6. **Premiers tests.** `sanitize_doi()`, `format_yml()`, l'aller-retour des
   métadonnées sur les jeux d'essai de l'étape 2.
7. **Aligner sur le skill** (D3, D4). Chemins explicites pour le README,
   correction de « directoryies » et du champ `Path:`, argument `dataverse`
   retiré de `modify_datasets()`, valeur de retour de `get_datasets_metadata()`
   conforme à sa documentation. Puis mettre à jour le point « lien avec
   dataverseuR » de la feuille de route du skill.

Plus tard : passer à `httr2`, des tests d'API avec `vcr`, les liens vers le
guide Dataverse courant, la mise à jour du README (et un badge « experimental »
tant qu'il n'y a pas de tests), un point d'accès de remplacement de fichier, les
unités QUDT/UCUM dans le README généré.

## Sources

- Code et historique : `R/*.R`, `DESCRIPTION`, `.Rbuildignore`, `git log`,
  `git ls-files`, `du -sh` (2026-10-19).
- `R CMD check --as-cran` sur `git archive HEAD` (R 4.6.1), 2026-10-19.
- Intégration continue : https://api.github.com/repos/lou-heraut/dataverseuR/actions/runs
  (consulté le 2026-10-19).
- r-lib/actions, `check-r-package`, valeur par défaut de `error-on` :
  https://github.com/r-lib/actions/tree/v2/check-r-package
- Dépôt du skill : `claude-code-curation-rdg/skills/curation-rdg/SKILL.md`,
  `ROADMAP.md`, `dev/decisions.md` (état du 2026-10-17).
- Wickham, H. & Bryan, J. *R Packages* (2e éd.), chapitres « Other components »
  et « Other markdown files » : https://r-pkgs.org/misc.html,
  https://r-pkgs.org/other-markdown.html
- httr, statut « superseded » : https://httr.r-lib.org/
- Client R `dataverse` (IQSS), README CRAN 0.3.16 :
  https://cran.r-project.org/package=dataverse
- Guide de l'API Dataverse, v6.12.1 : https://guides.dataverse.org/en/latest/api/native-api.html
- `mcptools` 1.0.0 : https://opensource.posit.co/blog/2026-07-06_mcptools-1-0-0/
- Skills de Claude Code : https://code.claude.com/docs/en/skills
- rOpenSci, `vcr` : https://docs.ropensci.org/vcr/
- Data Curation Network (2022), *CURATE(D) Steps and Checklist*, v2 :
  https://conservancy.umn.edu/items/2449305b-4cdc-4fbc-9902-2795b020c939
