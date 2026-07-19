# ROADMAP — Plan de formation IAM par la pratique

Objectif final : être capable de concevoir, déployer, sécuriser et faire évoluer une
infrastructure IAM d'entreprise — pas seulement savoir cliquer dans une console Keycloak.

Le plan suit une logique volontaire : **cœur SSO/IdP d'abord (Keycloak seul), puis
annuaire, puis protocoles en profondeur, puis les briques d'architecte** (autorisation
fine, gouvernance, comparatif produit). C'est aussi l'ordre dans lequel un vrai projet
IAM se construit en entreprise.

Chaque phase a : un objectif, les concepts à maîtriser avant de commencer, ce qu'on
construit concrètement, et une checklist de sortie ("definition of done").

---

## Phase 0 — Prérequis et environnement

**Objectif** : avoir un environnement de travail reproductible.

- Docker + Docker Compose v2 installés et fonctionnels.
- Un éditeur (VS Code) + `curl`/`jq` pour manipuler les API REST.
- Comprendre la différence *conteneur de dev* (`start-dev`, H2 mémoire) vs
  *déploiement prod-like* (`start --optimized`, Postgres, TLS) — Keycloak est très
  strict là-dessus et c'est un piège classique de débutant.

**Definition of done** : `docker compose version` fonctionne, tu as un dossier de
travail par phase, tu as lu `docs/fondamentaux/01-bases-iam-authn-vs-authz.md`.

---

## Phase 1 — Keycloak seul : le socle SSO/IdP

**Concepts à lire avant** : `01-bases-iam-authn-vs-authz.md`, `02-oauth2.md`, `03-oidc.md`.

**Objectif** : comprendre Keycloak comme *Identity Provider (IdP)* central : realms,
clients, utilisateurs, rôles, flux d'authentification.

Ce qu'on construit :

- Keycloak + Postgres via Docker Compose (mode dev, base réaliste).
- Un realm dédié (jamais le realm `master`, réflexe à prendre dès le début).
- Un client "confidential" (backend) et un client "public" (SPA) pour comprendre la
  différence de sécurité entre les deux.
- Un utilisateur de test, des rôles realm et des rôles client.
- Premier login via le compte de service (`account console`) pour visualiser un
  flux OIDC "authorization code" de bout en bout dans les logs.

**Definition of done** :

- Tu sais expliquer la différence entre un rôle *realm* et un rôle *client*.
- Tu sais retrouver et lire un `access_token` (JWT) décodé et en expliquer chaque claim.
- Tu as exporté ton realm en JSON (Import/Export) — c'est ton premier artefact
  versionné dans Git.

---

## Phase 2 — Fédération d'annuaire avec LLDAP

**Concepts à lire avant** : `06-ldap-annuaires.md`.

**Objectif** : comprendre pourquoi les entreprises ne stockent (presque) jamais les
utilisateurs *dans* l'IdP, mais dans un annuaire séparé — et comment Keycloak s'y
connecte en lecture (voire écriture) via **User Federation**.

Ce qu'on construit :

- LLDAP (annuaire LDAP léger, écrit en Rust, une alternative moderne et simple à
  OpenLDAP — cf. l'article de Stéphane Robert) en tant que source de vérité des
  utilisateurs.
- Connexion Keycloak → LLDAP via un provider LDAP (bind DN, base DN, mapping
  d'attributs).
- Un utilisateur créé côté LLDAP et visible côté Keycloak après synchronisation.

**Definition of done** :

- Tu sais expliquer bind DN, base DN, et la différence *sync* périodique vs *lookup*
  à la demande.
- Tu as un utilisateur "LLDAP-native" qui se connecte à une application via Keycloak,
  sans jamais avoir été créé manuellement dans Keycloak.

**Extension confirmée (à faire quand tu veux, pas bloquant)** : brancher **OpenLDAP**
en parallèle de LLDAP sur un second provider User Federation, et comparer les deux à
l'usage — schéma LDIF à écrire à la main, ACL plus complexes, mais nettement plus
représentatif d'un annuaire d'entreprise réel (souvent la base d'un Active Directory
ou d'un legacy Linux). Utile pour un profil architecte : LLDAP prouve le concept vite,
OpenLDAP montre le vrai coût d'exploitation.

---

## Phase 3 — OIDC, SAML et cycle de vie des tokens en profondeur

**Concepts à lire avant** : `02-oauth2.md`, `03-oidc.md`, `04-saml2.md`, `09-tokens-jwt-refresh-securite.md`.

**Objectif** : ne plus jamais confondre OAuth2 et OIDC, comprendre SAML par la
pratique, et maîtriser le cycle de vie complet d'un token (émission, refresh,
révocation, introspection).

Ce qu'on construit :

- Un flux **Authorization Code + PKCE** rejoué à la main avec `curl` (script fourni),
  pour voir exactement ce qui transite : `code_verifier`, `code_challenge`, `code`,
  `access_token`, `refresh_token`, `id_token`.
- Une petite application Node.js (client OIDC réel) qui fait login, affiche les
  claims de l'ID Token, et déclenche un **refresh token grant** à la demande — pour
  observer la rotation de token en direct.
- Un exercice **SAML 100% dans Keycloak** : un second realm configuré comme
  *Identity Provider SAML* du premier, pour comprendre l'assertion SAML, le
  binding POST, et la fédération SAML sans dépendance externe.
- Introspection de token (`/token/introspect`) et révocation (`/logout`,
  `/revoke`) pour comprendre la différence entre un JWT auto-porteur et un
  token opaque.
- **Bonus** : le grant **Client Credentials** (machine-à-machine, sans utilisateur
  humain) avec le compte de service de `demo-backend` — le seul grant OAuth2 courant
  qu'on n'aurait sinon jamais testé dans ce lab.

**Definition of done** :

- Tu peux dessiner de mémoire le séquence-diagramme Authorization Code + PKCE.
- Tu sais dire en une phrase ce qu'apporte OIDC par rapport à OAuth2 pur (réponse :
  un ID Token normalisé + un moyen standard de connaître l'identité de l'utilisateur,
  là où OAuth2 seul ne fait que déléguer un accès).
- Tu as observé une assertion SAML brute (XML, signée) au moins une fois.
- Tu sais expliquer quand utiliser Client Credentials plutôt qu'Authorization Code
  (réponse : dès qu'il n'y a pas d'utilisateur humain derrière l'appel).

---

## Phase 4 — Autorisation fine avec OpenFGA (ReBAC)

**Concepts à lire avant** : `08-autorisation-rbac-abac-rebac.md`.

**Objectif** : comprendre les limites du RBAC dès que les règles métier deviennent
relationnelles ("Alice peut éditer ce document parce qu'elle est dans l'équipe
propriétaire du dossier parent"), et voir comment une architecture moderne sépare
**authentification** (Keycloak) et **autorisation fine** (OpenFGA, inspiré du papier
Google Zanzibar).

Ce qu'on construit :

- OpenFGA + Postgres via Docker Compose.
- Un modèle d'autorisation (`.fga`) type gestion documentaire : `owner`, `editor`,
  `viewer`, avec héritage de permissions via des relations (dossier → document).
- Des relations (`tuples`) écrites via l'API, et des `Check` / `ListObjects` pour
  vérifier des permissions.
- Un point d'architecture : comment un token OIDC émis par Keycloak (le `sub` du
  JWT) devient le `user` dans les tuples OpenFGA — le pont entre les deux mondes.

**Definition of done** :

- Tu sais expliquer la différence RBAC / ABAC / ReBAC avec un exemple pour chacun.
- Tu as un modèle `.fga` versionné qui répond correctement à au moins 3 scénarios
  de `Check` différents (autorisé, refusé, hérité).

---

## Phase 5 — Gouvernance des identités (IGA) avec midPoint

**Concepts à lire avant** : `01-bases-iam-authn-vs-authz.md` (section cycle de vie),
la playlist [MidPoint Tutorials](https://www.youtube.com/playlist?list=PLUMkpGpxB09_Ag-Wps2lo1BYM6DcOAOBo).

**Objectif** : comprendre la différence entre un **IdP/SSO** (Keycloak — l'exécution
de l'authentification) et une plateforme **IGA** (midPoint — la gouvernance : d'où
viennent les comptes, qui les approuve, quand ils sont désactivés). C'est la brique
qui distingue un profil "administrateur IAM" d'un profil "architecte IAM".

Ce qu'on construit :

- midPoint + Postgres via Docker Compose (image officielle Evolveum).
- Une ressource source (ex. fichier CSV ou LDAP — LLDAP de la phase 2) et une
  ressource cible.
- Un exercice de **reconciliation** (rapprochement entre la source et le système
  cible) et un exercice de provisioning / déprovisioning automatique.
- Une lecture des concepts RBAC avancés de midPoint (rôles métier, *archetypes*,
  contraintes temporelles).

**Definition of done** :

- Tu sais expliquer la différence entre *Identity Management (IdM)*, *Identity
  Governance (IGA)* et *Access Management (AM)* — trois métiers souvent confondus.
- Tu as vu au moins une fois un cycle complet : création d'identité côté source →
  provisioning automatique → désactivation → déprovisioning.

---

## Phase 6 — Regard d'architecte : Keycloak vs Zitadel

**Objectif** : ne pas rester mono-outil. Un architecte IAM doit savoir comparer des
solutions selon des critères (modèle de données, multi-tenance, scalabilité, coût
d'exploitation), pas seulement savoir utiliser un produit.

Ce qu'on construit :

- Zitadel via son Docker Compose officiel, à côté de la stack Keycloak.
- Un tableau comparatif que **tu rédiges toi-même** après usage (pas avant) :
  modèle de tenancy (realms vs organisations/instances), architecture
  (event-sourcing chez Zitadel vs modèle relationnel classique chez Keycloak),
  API-first vs admin console centrale, coût d'exploitation perçu.

**Definition of done** :

- Tu as un document `phase-6-zitadel-comparatif/COMPARATIF.md` écrit par toi,
  avec au moins 5 critères et un avis argumenté (pas un simple copier-coller de
  tableau marketing).

---

## Phase 7 — Fédération hybride avec Microsoft Entra ID

**Objectif** : ne pas rester dans un monde 100% Keycloak. La majorité des grandes
entreprises ont déjà Entra ID (ex-Azure AD) quelque part dans leur SI — savoir le
faire cohabiter avec un IdP self-hosted (fusion-acquisition, partenariat,
migration progressive) est une vraie compétence d'architecte, distincte de
"savoir utiliser Entra ID seul".

Deux montages possibles, à choisir selon ce que tu veux observer :

- **Entra ID comme IdP upstream de Keycloak** (Identity Brokering OIDC) :
  Keycloak délègue l'authentification à Entra ID — utile quand Keycloak reste le
  point d'entrée unique pour tes applications, mais que les comptes vivent dans
  Entra ID (scénario le plus courant en entreprise : SSO centralisé sur l'IdP
  cloud existant).
- **Keycloak comme IdP externe d'une application enregistrée dans Entra ID** :
  l'inverse — utile pour comprendre le point de vue d'Entra ID quand *lui* fait
  confiance à un tiers.

Ce qu'on construit :

- Une application enregistrée dans ton tenant Entra ID (App registrations).
- Un Identity Provider OIDC dans Keycloak pointant vers ce tenant (endpoints
  `login.microsoftonline.com`), avec mapping des claims Entra ID
  (`oid`, `upn`, groupes) vers des attributs/rôles Keycloak.
- Un test de connexion de bout en bout avec un vrai compte de ton tenant.

**Definition of done** :

- Tu sais expliquer la différence entre *brokering* (Keycloak délègue à Entra ID)
  et *fédération SP* (une appli fait confiance à Keycloak qui fait confiance à
  Entra ID) — un attendu classique d'entretien architecte.
- Un utilisateur réel de ton tenant Entra ID s'est connecté avec succès via
  Keycloak.

---

## Après le plan : pistes pour la suite (architecte confirmé)

Une fois les 7 phases terminées, pistes crédibles pour la suite (non détaillées ici,
à construire au fur et à mesure) :

- Haute disponibilité de Keycloak (cluster, cache distribué, Postgres répliqué).
- Keycloak derrière un reverse proxy (Traefik) avec TLS et durcissement (cf. les
  guides Traefik du blog de Stéphane Robert).
- SCIM en pratique (Keycloak 26.7+ propose un SCIM provisioning en preview).
- Passkeys / WebAuthn sans mot de passe de bout en bout.
- Zero Trust et bastion d'accès (Teleport, Pomerium) branchés sur le même IdP.
- Étude du client Rust `openfga-client` (vakamo-labs) si tu veux consommer OpenFGA
  depuis une application Rust plutôt qu'en HTTP brut.

---

## Suivi de progression

Coche au fur et à mesure (édite ce fichier, commit à chaque étape franchie) :

- [x] Phase 0 — Environnement prêt
- [x] Phase 1 — Keycloak core
- [x] Phase 2 — LLDAP + fédération
- [ ] Phase 2 bis — OpenLDAP (comparatif, optionnel)
- [x] Phase 3 — OIDC/SAML/tokens
- [ ] Phase 4 — OpenFGA (ReBAC)
- [ ] Phase 5 — midPoint (IGA)
- [ ] Phase 6 — Comparatif Zitadel
- [ ] Phase 7 — Entra ID (fédération hybride)
