# Décisions

Les choix qui ont émergé du travail, avec leur date et leur raison.

## 2026-10-19

Issus de l'audit `dev/audits/2026-10-19_project-structure.md`.

- **La curation vit hors du dépôt.** Les dossiers de curation (un par jeu) sont
  dans un dossier de curation local, hors de GitHub. Les anciens, qui étaient
  dans `dev/dataverse_*`, y sont archivés tels quels comme trace du travail
  passé ; les nouvelles curations suivent la forme du skill `curation-rdg`.
  Raison : ce dépôt est public, ces dossiers contiennent des brouillons et des
  données de déposants, et pesaient 9,2 Go.
- **Aucune donnée de jeu dans le dépôt**, ni de curation ni d'essai.
  `dev/dataverse_manual_example/` sort du suivi ; l'historique le garde, ce qui
  est sans conséquence puisque le jeu concerné (5EBITB) est publié (DataCite,
  vérifié le 2026-10-19).
- **Le skill reste indépendant du paquet.** Il peut curer sans dataverseuR et
  s'en sert quand c'est utile : appels à l'API, génération du README, scripts R
  de suivi de curation que les déposants peuvent relire et réutiliser. Pas de
  serveur MCP.
- **Les README générés restent génériques** : aucun chemin de la machine qui
  les produit. Le champ `Path:` actuel, qui écrit le chemin local, est un
  défaut à corriger.
- **Licence GPL-3**, comme ASHE : `DESCRIPTION` et les en-têtes le disaient
  déjà ; le texte de `LICENSE` (AGPL) et `codemeta.json` s'alignent.
- **Journal des versions : `CHANGELOG.md`** au format Keep a Changelog, comme
  les autres projets, exclu du paquet construit par `.Rbuildignore`.
  `NEWS.md` (la convention R et GNU pour la même chose) n'apporterait que
  l'affichage par pkgdown et CRAN, que ce paquet n'utilise pas.
- **`test.R` n'est pas un fichier de tests** : c'est le script de pilotage de
  Lou (un vecteur `to_do`, un bloc par action), la même forme que les scripts
  de `dataverseuR_toolbox`, d'Explore2 ou d'EXstat. On garde cette forme,
  humaine et lisible, qui est aussi celle des scripts de suivi de curation
  qu'on voudrait donner aux déposants. Il devient `dev/main.R`, avec trois
  règles : chaque bloc définit ses entrées en tête, aucun chemin propre à une
  machine, un passage complet sur l'instance démo avant chaque version. Une
  version pour les utilisateurs ira dans `dataverseuR_toolbox`.
- **Les fonctions reçoivent leurs dossiers en arguments** au lieu de les
  dériver du DOI (`{doi}/`, `{doi}_cleaned/`). La gestion actuelle des chemins
  est fragile et ne s'accorde pas avec le dossier par jeu du skill.
- **La conversion des tableaux vers un CSV propre pour Dataverse reste un
  besoin central** : c'est l'une des étapes les plus fréquentes de la curation,
  depuis toutes sortes de formats mal fichus. `ASHE::convert_tibble()` relit
  les valeurs (types devinés, dates converties) et peut donc les changer ; il
  lui faut un équivalent qui garde les valeurs telles quelles. Où il vit (ASHE
  ou dataverseuR) se décidera avec un audit d'ASHE.
