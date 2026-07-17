# Comparatif Keycloak vs Zitadel — à compléter après usage

> Consigne (voir `ROADMAP.md`, Phase 6) : remplis ce document **après** avoir
> manipulé Zitadel, pas avant. L'objectif est ton propre avis argumenté, pas
> un tableau marketing recopié.

## Contexte du comparatif

- Version Keycloak testée :
- Version Zitadel testée :
- Cas d'usage évalué (ex. SSO pour 3 applications internes, B2B multi-clients...) :

## Grille de comparaison (complète chaque ligne toi-même)

| Critère | Keycloak | Zitadel | Mon avis |
|---|---|---|---|
| Modèle de multi-tenance (realm vs organisation/instance) | | | |
| Modèle de données interne (relationnel vs event-sourcing) | | | |
| Facilité de prise en main de la console admin | | | |
| Richesse de l'API (REST/gRPC, exhaustivité) | | | |
| Écosystème de connecteurs / identity brokering | | | |
| Effort d'exploitation perçu (mise à jour, sauvegarde, HA) | | | |
| Personnalisation des écrans de login | | | |
| Support SCIM natif | | | |
| Maturité de la documentation | | | |

## Ce que je retiens

*(2-3 paragraphes, tes mots : dans quel contexte choisirais-tu l'un plutôt que
l'autre, en tant qu'architecte devant justifier ce choix à une équipe ?)*

## Question d'architecte à te poser

Un realm Keycloak est-il vraiment l'équivalent d'une organisation Zitadel ?
Regarde comment chacun isole les données et les politiques de sécurité entre
tenants avant de répondre — la réponse n'est pas aussi simple qu'elle en a
l'air, et c'est exactement le genre de nuance qu'on attend d'un architecte en
entretien.
