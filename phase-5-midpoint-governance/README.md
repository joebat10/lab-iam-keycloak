# Phase 5 — Gouvernance des identités (IGA) avec midPoint

Lire avant de commencer : la section "cycle de vie" de
`../docs/fondamentaux/01-bases-iam-authn-vs-authz.md`, puis parcourir
quelques épisodes de la playlist
[MidPoint Tutorials](https://www.youtube.com/playlist?list=PLUMkpGpxB09_Ag-Wps2lo1BYM6DcOAOBo)
pour te repérer visuellement dans l'interface avant de la manipuler.

> midPoint est une application Java/Spring plus lourde que Keycloak ou LLDAP.
> Prévois quelques minutes de démarrage au premier lancement (initialisation
> du schéma), et davantage de RAM disponible (2-4 Go recommandés pour la JVM).

## Démarrer la stack

```bash
cd phase-5-midpoint-governance
cp .env.example .env
docker compose up -d
docker compose logs -f midpoint   # attends "midPoint Spring Application ... started"
```

Console : <http://localhost:8888/midpoint>
Login : `administrator` / la valeur de `MIDPOINT_ADMIN_PASSWORD` de ton `.env`.

> Ce `docker-compose.yml` est adapté du dépôt officiel
> [Evolveum/midpoint-docker](https://github.com/Evolveum/midpoint-docker)
> (démo "native repository"). Si tu rencontres une erreur au démarrage, compare
> avec la version canonique et la doc officielle avant de creuser plus loin :
> <https://docs.evolveum.com/midpoint/install/containers/docker/>

## Objectif de cette phase

Ne pas confondre trois métiers que ce lab t'a fait toucher séparément :

| | Répond à | Outil dans ce lab |
|---|---|---|
| **Access Management (AM)** | Comment un utilisateur s'authentifie *maintenant* | Keycloak |
| **Identity Management (IdM)** | Où vivent les comptes utilisateurs | LLDAP |
| **Identity Governance (IGA)** | D'où vient un compte, qui l'a approuvé, quand il doit disparaître | midPoint |

## Exercice 1 — Une ressource source (CSV)

midPoint propose un connecteur CSV prêt à l'emploi, idéal pour un premier
exercice sans dépendance externe :

1. Crée un fichier `hr-source.csv` avec quelques colonnes (`login`,
   `firstName`, `lastName`, `department`, `status`).
2. Dans la console midPoint : **Resources → New resource → CSV connector**,
   pointe vers ce fichier.
3. Configure le **schema handling** pour mapper les colonnes CSV aux
   attributs midPoint.
4. Lance une **Import from resource** — chaque ligne du CSV devient une
   identité (`FocusType: UserType`) dans midPoint.

## Exercice 2 — Réconciliation

1. Modifie une ligne du CSV (change `department`).
2. Relance une tâche de **Reconciliation** sur la ressource : midPoint
   détecte l'écart et met à jour l'identité correspondante — c'est le
   mécanisme qui garde les identités synchronisées avec leur source de vérité
   même sans notification en temps réel.

## Exercice 3 — Provisioning vers LLDAP (optionnel, avancé)

Si tu veux aller plus loin : configure une seconde ressource pointant vers
le LLDAP de la Phase 2 (connecteur LDAP), et un **outbound mapping** qui crée
automatiquement un compte LLDAP pour chaque nouvelle identité midPoint —
c'est le provisioning automatisé, la brique qui manque à Keycloak seul.

## Exercice 4 — RBAC avancé midPoint

Regarde les concepts de **Role**, **Org unit** et **Archetype** dans midPoint
(Roles → New role) — plus riches que les rôles Keycloak : ils supportent des
contraintes temporelles (accès valable seulement pendant une période) et des
règles d'attribution automatique (assignation d'un rôle selon un attribut,
ex. tous les membres du département "Finance").

## Definition of done de cette phase

- [ ] Tu sais expliquer la différence AM / IdM / IGA sans hésiter.
- [ ] Tu as importé des identités depuis une ressource CSV.
- [ ] Tu as vu un cycle de réconciliation détecter un écart et corriger une
      identité automatiquement.

## Suite

→ `../phase-6-zitadel-comparatif/README.md`
