# SCIM — provisioning et déprovisioning standardisés

## Le problème que SCIM résout

OIDC et SAML répondent à "comment s'authentifier". Ils ne répondent pas à "comment
un compte utilisateur apparaît, se met à jour, et disparaît automatiquement dans
une application tierce quand un salarié arrive, change de service, ou part."

Sans standard, chaque fournisseur SaaS invente sa propre API de provisioning.
**SCIM (System for Cross-domain Identity Management)** normalise ça : un schéma
JSON commun pour les utilisateurs/groupes, et une API REST commune
(`/Users`, `/Groups`) pour créer/lire/mettre à jour/désactiver des comptes.

## Où SCIM se situe dans l'architecture

```
Source d'identité (RH, midPoint, annuaire) 
        │  SCIM (provisioning automatique)
        ▼
Application cible (SaaS, ou Keycloak lui-même)
```

SCIM est complémentaire à OIDC/SAML, pas concurrent : OIDC/SAML gèrent la
connexion *au moment où l'utilisateur se connecte*, SCIM gère l'existence même
du compte, en amont, indépendamment d'une connexion.

## Ce que fait un serveur SCIM

- `POST /Users` : créer un compte.
- `PATCH /Users/{id}` : mettre à jour des attributs (changement de nom, de
  service...).
- `DELETE /Users/{id}` (ou `active: false` via PATCH) : désactiver/déprovisionner.
- `GET /Users?filter=...` : rechercher, pour la réconciliation périodique.

## Pertinence directe pour ce lab

- **Keycloak 26.7+** propose une API de provisioning SCIM (en preview) : un bon
  sujet d'exploration après la Phase 1, pour voir Keycloak à la fois comme
  IdP (SSO) et comme cible de provisioning SCIM.
- **midPoint (Phase 5)** peut agir comme *source* de vérité qui pousse des
  comptes via SCIM vers des applications tierces — c'est exactement le rôle
  d'une plateforme IGA dans une architecture SCIM.

## À retenir pour un entretien

> SCIM standardise le *provisioning* (création/synchronisation/suppression de
> comptes), là où OIDC/SAML standardisent l'*authentification*. Une architecture
> IAM mature a besoin des deux, souvent portés par des outils différents : un IdP
> pour l'authentification (Keycloak), et une plateforme IGA ou un connecteur SCIM
> dédié pour le provisioning (midPoint, ou l'API SCIM native d'un SaaS).
