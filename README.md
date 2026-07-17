# lab-iam-keycloak

Projet fil rouge pour apprendre l'IAM (Identity & Access Management) par la pratique,
avec pour objectif de progresser vers un poste d'**ingénieur IAM**, puis d'**architecte IAM**.

> Ce dépôt est construit progressivement, phase par phase. Chaque dossier `phase-N-*`
> est un chapitre autonome : il se lance seul (`docker compose up`), a son propre README
> avec des objectifs pédagogiques clairs, et s'appuie sur les phases précédentes.

## Pourquoi ce projet

Monter une stack IAM soi-même — et pas seulement lire de la théorie — est la manière
la plus efficace de comprendre en profondeur :

- **AuthN vs AuthZ** : qui es-tu ? vs qu'as-tu le droit de faire ?
- **SSO / IdP** : comment un utilisateur s'authentifie une fois et accède à plusieurs
  applications.
- **OAuth 2.0** : délégation d'autorisation, grants, scopes.
- **OpenID Connect (OIDC)** : la couche d'identité au-dessus d'OAuth2 (ID Token, userinfo).
- **SAML 2.0** : le standard fédératif historique, encore central en entreprise.
- **SCIM** : provisioning/déprovisioning automatisé des comptes.
- **LDAP et annuaires** : la source de vérité historique des identités.
- **MFA / WebAuthn** : facteurs additionnels et authentification sans mot de passe.
- **RBAC / ABAC / ReBAC** : les modèles d'autorisation, du plus simple au plus fin.
- **Tokens, refresh, rotation, révocation** : le cœur de la sécurité opérationnelle.
- **Gouvernance des identités (IGA)** : cycle de vie, recertification, séparation des tâches.

## Structure du dépôt

```
lab-iam-keycloak/
├── ROADMAP.md                     <- Le plan de formation complet, phase par phase
├── docs/fondamentaux/             <- Notes de cours (concepts, à lire avant chaque phase)
├── phase-0-prerequis/             <- Environnement de travail (Docker, réseau, outils)
├── phase-1-keycloak-core/         <- Installer et administrer Keycloak seul
├── phase-2-lldap-federation/      <- Brancher un annuaire LDAP (LLDAP) sur Keycloak
├── phase-3-oidc-saml-tokens/      <- Clients OIDC/SAML réels, flux de tokens, refresh
├── phase-4-openfga-authz/         <- Autorisation fine (ReBAC) en complément du RBAC
├── phase-5-midpoint-governance/   <- Gouvernance des identités (IGA) avec midPoint
├── phase-6-zitadel-comparatif/    <- Regard d'architecte : Keycloak vs Zitadel
├── resources/                     <- Sources externes utilisées, avec correctifs
└── scripts/                       <- Scripts transverses (cheatsheets, tests de flux)
```

## Comment progresser

1. Lis `ROADMAP.md` en entier une première fois — c'est la carte du projet.
2. Traite les fiches `docs/fondamentaux/` dans l'ordre, **avant** de commencer la phase
   qui les utilise (indiqué dans chaque README de phase).
3. Avance phase par phase. Ne saute pas la phase 1 : c'est le socle de tout le reste.
4. Documente ce que tu apprends directement dans les README (ajoute tes captures
   d'écran, tes erreurs rencontrées et comment tu les as résolues — c'est ce qui a
   de la valeur pour un recruteur qui regarde ton GitHub).

## Prérequis matériels

- Une machine avec Docker + Docker Compose v2 (Linux natif, WSL2, ou une VM).
- ~4 Go de RAM libres pour Keycloak + Postgres, prévoir plus si tu ajoutes midPoint
  (JVM, plus gourmand) en phase 5.
- Aucune connaissance IAM préalable n'est supposée : tout est expliqué dans
  `docs/fondamentaux/`.

## Licence

MIT — ce dépôt est un projet d'apprentissage personnel, libre à toi de le forker,
l'adapter, le partager.
