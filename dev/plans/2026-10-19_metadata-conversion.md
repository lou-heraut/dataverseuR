# Réécriture de la conversion des métadonnées

État : en cours, ouvert le 2026-10-19. Point 1 de `ROADMAP.md`.

## Pourquoi

L'aller-retour YAML ↔ JSON (`generate_metadata_json()`,
`convert_metadata_to_yml()`) passe par cinq étapes :

1. il aplatit l'arbre des métadonnées en table ;
2. il renumérote chaque nom de sous-champ selon son rang ;
3. il recopie le modèle JSON autant de fois que le plus grand numéro ;
4. il remplit ce modèle nom par nom, en parcourant tout l'arbre à chaque
   valeur ;
5. il boucle pour retirer ce qui est resté vide.

La renumérotation par rang fait glisser ou perdre des sous-champs ; les défauts
sont listés dans `ROADMAP.md`. Or la forme du YAML suit déjà celle du JSON de
Dataverse. La réécriture traduit donc l'un dans l'autre directement : le modèle
ne sert plus qu'à dire, pour chaque champ, son bloc, s'il est multiple et son
type.

## Ce qui ne change pas

- Le format du YAML, son en-tête, la ligne vide entre deux champs et la
  signature des deux fonctions.
- La licence (etalab 2.0) et la langue des métadonnées, reprises du modèle.
- Un sous-champ écrit seul forme l'unique élément de son champ, si ce champ
  n'est pas écrit par ailleurs. C'est le cas de `country: Fiji` dans
  `inst/templates/metadata_template.yml`.

## Ce qui change

- Chaque sous-champ reste avec son élément.
- Les valeurs sont lues comme elles sont écrites (`1.10`, `no`).
- Trois cas arrêtent la conversion avec un message, là où l'ancien code les
  perdait ou les rattachait au hasard : un champ inconnu, un sous-champ
  inconnu, et un sous-champ écrit seul alors que son champ est écrit.

## Étapes

1. [x] Tests sur un YAML inventé (`tests/testthat/`), 19 cas.
2. [x] Prototype dans un brouillon. Les 19 tests passent. Sur les 15 YAML
   d'Explore2 de `dataverseuR_toolbox` et sur le modèle du paquet, il envoie
   les mêmes valeurs que l'ancien code, sauf là où l'ancien code déplaçait des
   sous-champs (voir plus bas).
3. [ ] Reporter la réécriture dans `R/metadata.R` et `R/tools.R`, et retirer
   les fonctions devenues inutiles. L'aide des tests passe par `read_yml()`.
4. [ ] `R CMD check --as-cran` sans avertissement.
5. [ ] Essai de bout en bout sur l'instance de démonstration : créer un jeu
   depuis le YAML inventé, relire ses métadonnées, comparer, puis supprimer le
   brouillon.
6. [ ] Lecture seule d'un jeu réel de l'entrepôt (MAKAHO) : télécharger,
   convertir, regénérer, comparer les valeurs.
7. [ ] `CHANGELOG.md` et `ROADMAP.md`.

## Constats en route

- Le modèle JSON range un sous-champ sous la clé `keywordTermURI` alors que son
  nom est `keywordTermURL`. C'est le seul écart de ce type. La réécriture
  indexe les sous-champs par leur nom.
- Les adresses des mots-clés sont écrites sous le mauvais mot-clé dans 13 des
  15 YAML d'Explore2 de la boîte à outils. Par exemple, `c_1352` est écrit
  sous « hydrological model », alors que sur RDG il désigne « temporal
  aggregation », comme le montrait le jeu doi:10.57745/2YPNZ7. Le glissement de
  l'ancien code les remettait à leur place.
- Dans un 14e fichier (`series-horizons/metadata/all.yml`), un
  `datasetContactEmail` est écrit hors de son élément.
- Avec la réécriture, ces fichiers sont à réaligner avant de resservir.
