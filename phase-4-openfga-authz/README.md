# Phase 4 — Autorisation fine avec OpenFGA (ReBAC)

Lire avant de commencer : `../docs/fondamentaux/08-autorisation-rbac-abac-rebac.md`.

## Démarrer la stack

```bash
cd phase-4-openfga-authz
cp .env.example .env
docker compose up -d
curl -sf http://localhost:8081/healthz && echo OK
```

Playground web (visualisation du modèle) : <http://localhost:3001/playground>

## Installer le CLI `fga`

```bash
# macOS / Linuxbrew
brew install openfga/tap/fga

# ou : télécharger le binaire précompilé correspondant à ton OS/arch
# depuis https://github.com/openfga/cli/releases
```

## Le modèle de démonstration

`model/document-model.fga` modélise un système documentaire simple :

```
type folder
  relations
    define owner: [user]
    define editor: [user] or owner
    define viewer: [user] or editor

type document
  relations
    define parent: [folder]
    define owner: [user]
    define editor: [user] or owner or editor from parent
    define viewer: [user] or editor or viewer from parent
```

Le point important : `editor from parent` et `viewer from parent` sont des
relations **héritées** (tuple-to-userset). Un document n'a pas besoin d'une
relation explicite pour chaque utilisateur ayant accès à son dossier parent —
la règle est écrite une seule fois dans le modèle et s'applique à tout
document créé dans ce dossier, présent ou futur.

## Lancer la démo

```bash
cd scripts
./openfga-demo.sh
```

Le script crée un store, y écrit le modèle, ajoute 3 relations
(`alice owner folder:projet-x`, `bob viewer folder:projet-x`,
`folder:projet-x parent document:roadmap`), puis vérifie 4 permissions et
affiche le résultat attendu à côté de chacune.

## Exercice à faire toi-même

Réutilise le `STORE_ID` et `MODEL_ID` affichés par le script pour :

1. Ajouter un troisième utilisateur `carl` comme `owner` direct de
   `document:roadmap` (pas via le dossier) — vérifie qu'il peut éditer, même
   sans aucune relation sur `folder:projet-x`.
2. Retirer la relation de `bob` sur le dossier (`fga tuple delete ...`) et
   vérifie qu'il perd immédiatement l'accès au document — sans qu'aucune
   ligne de code applicatif n'ait eu besoin de changer.

## Le pont avec Keycloak (à garder en tête, pas à coder dans cette phase)

Dans une architecture réelle, le `sub` du JWT émis par Keycloak (phase 1)
devient l'identifiant `user:<sub>` utilisé dans les tuples OpenFGA — c'est le
point de jonction entre "qui es-tu" (Keycloak) et "que peux-tu faire sur
*cette* ressource précise" (OpenFGA). Le client Rust `openfga-client`
(vakamo-labs, voir `../resources/liens-references.md`) est une option pour
consommer l'API OpenFGA côté backend si ton application est en Rust.

## Definition of done de cette phase

- [ ] Tu sais expliquer `tuple-to-userset` avec tes propres mots.
- [ ] Le script `openfga-demo.sh` tourne et les 4 `Check` renvoient le
      résultat attendu.
- [ ] Tu as fait l'exercice de retrait de relation et observé l'effet immédiat.

## Suite

→ `../phase-5-midpoint-governance/README.md`
