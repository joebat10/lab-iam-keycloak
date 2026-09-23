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

**Extension confirmée (retour sur cette phase après la Phase 4)** : Keycloak natif
propose plusieurs fonctionnalités qu'on n'a pas encore touchées, identifiées en
comparant ce lab à un vrai programme de formation professionnelle Keycloak :

- **Groups natifs Keycloak** (menu *Groups*, pas les groupes LDAP synchronisés de la
  Phase 2) : crée un groupe, assigne-lui un rôle, ajoute `alice` dedans — utile dès
  que le nombre de comptes augmente, pour ne plus assigner les rôles un par un.
- **Client bearer-only** : un troisième type de client, ni confidentiel ni public —
  un pur *resource server* qui ne déclenche jamais de login lui-même, seulement de
  la validation de token (pas de redirect URI, pas de flow d'authentification). Crée
  un client `demo-api` en bearer-only pour voir la différence de configuration.
- **MFA/OTP + WebAuthn/Passkeys en pratique** : active `Configure OTP` et
  `Webauthn Register` dans *Authentication → Required actions*, connecte-toi avec
  `alice` et configure un TOTP (Google Authenticator ou équivalent) puis une passkey.
  Observe la différence de flow de connexion entre les deux.

Definition of done complémentaire : tu as un utilisateur qui se connecte avec MFA
activé, et tu sais expliquer la différence entre un client confidential/public/
bearer-only avec un exemple d'usage pour chacun.

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

**Extension confirmée (Phase 2 ter, en cours)** : brancher un vrai **Active Directory**
(Samba4, en local et gratuit) — contrairement à LLDAP et OpenLDAP qui sont des LDAP
génériques, Samba4 réimplémente le protocole Active Directory lui-même (DNS,
Kerberos, LDAP). Dans le scénario Norvalis (voir
`docs/scenario-entreprise-norvalis.md`), le site de Poitiers a gardé cet AD hérité,
jamais migré vers LLDAP — deux annuaires à faire cohabiter sur le même Keycloak.
Pertinent en particulier pour un poste où "Active Directory" est une compétence
requise, pas juste "un plus" (contrairement à SAML/OIDC dans certaines offres).

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

**Exercice D — SSO multi-applications réel + Single Logout (extension confirmée)**

Jusqu'ici, chaque exercice utilisait une seule application à la fois. Le vrai test du
SSO, c'est : se connecter une fois, accéder à *plusieurs* applications indépendantes
sans se reconnecter, puis se déconnecter une fois et perdre l'accès à toutes en même
temps.

1. Crée un second client OIDC public `demo-spa-2` (même config que `demo-spa` :
   Standard flow, PKCE, redirect URI `http://localhost:3001/*`).
2. Duplique `demo-app-oidc` en `demo-app-oidc-2` (change juste `OIDC_CLIENT_ID` et
   `PORT` dans son `.env`).
3. Connecte-toi sur la première appli (`localhost:3000`) avec `alice`.
4. Ouvre la seconde appli (`localhost:3001`) dans le même navigateur, clique
   "Se connecter" : tu dois arriver directement connecté, **sans repasser par
   l'écran de mot de passe** — c'est la session Keycloak (cookie sur
   `localhost:8080`) qui a fait le travail.
5. Déconnecte-toi depuis la première appli (`/logout`) : ouvre la seconde appli,
   rafraîchis — tu dois être déconnecté là aussi (*Single Logout* / déconnexion
   globale).

Definition of done complémentaire : tu as vu deux applications indépendantes
partager une seule session Keycloak, et une déconnexion sur l'une invalider l'autre.

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

## Phase 4 bis — Authentication Flows avancés et durcissement

**Objectif** : passer de "Keycloak qui marche" à "Keycloak configuré comme un vrai
RSSI l'exigerait". Cette phase couvre les contrôles de durcissement reconnus comme
standards de l'industrie pour Keycloak (isolation du master realm — déjà acquis
depuis la Phase 1 —, admin console, redirect URIs, PKCE, flows dépréciés, MFA
obligatoire pour les admins, patch management).

Ce qu'on construit :

- Un **Authentication Flow personnalisé** : copie le flow "browser" par défaut,
  ajoute une étape MFA **conditionnelle** (ex. obligatoire uniquement pour les
  utilisateurs d'un groupe `admins`, optionnelle pour les autres) — le pattern
  classique : Cookie → Identity Provider Redirector → Password/Passkey → MFA
  conditionnel.
- Un audit de tes clients existants (`demo-spa`, `demo-backend`) : vérifie qu'aucun
  redirect URI n'utilise de wildcard `*`, que *Implicit Flow* et
  *Direct Access Grants* (ROPC) sont bien désactivés.
- Une réflexion sur la restriction d'accès à la console d'admin par IP (l'exercice
  concret avec reverse proxy est en Phase 4 ter juste après).
- Une lecture des avis de sécurité Keycloak récents (`keycloak.org/security`) et une
  politique de patch management personnelle pour ce lab.

**Definition of done** :

- Tu as un flow d'authentification qui applique le MFA différemment selon le profil
  de l'utilisateur.
- Tu sais citer de mémoire les principaux contrôles de durcissement Keycloak et
  pourquoi chacun compte.
- Tu as vérifié et corrigé (si besoin) la configuration de tes clients existants
  selon ces contrôles.

---

## Phase 4 ter — Exploitation production : TLS, sauvegarde, clustering, audit

**Objectif** : la différence entre un lab qui tourne sur ta machine et une
infrastructure qu'on peut réellement mettre en production. La phase qui couvre le
plus de sujets "invisibles" tant que tout va bien, mais critiques au premier
incident réel.

Ce qu'on construit :

- **Reverse proxy TLS avec Traefik** : certificat Let's Encrypt (ou auto-signé en
  local), `KC_PROXY_HEADERS=xforwarded` et `KC_HOSTNAME` configurés — sans ça,
  Keycloak continue de générer des liens en `http://` même derrière un proxy HTTPS,
  un piège de configuration très répandu.
- **Sauvegarde et restauration réelles** : `pg_dump` de la base Postgres de Keycloak
  en plus de l'export de realm déjà pratiqué en Phase 1 — puis un vrai test de
  restauration sur un environnement propre (une sauvegarde jamais restaurée n'est
  pas une sauvegarde).
- **Clustering et haute disponibilité (concepts + mini-démo)** : comprendre le rôle
  du cache distribué Infinispan pour partager les sessions entre plusieurs nœuds
  Keycloak — un utilisateur ne doit jamais être déconnecté juste parce que sa
  requête suivante atterrit sur un autre nœud derrière un load balancer.
- **Logs, audit et investigation d'incident** : active l'enregistrement complet des
  événements (login ET admin events), génère volontairement plusieurs échecs de
  connexion consécutifs, puis retrouve et analyse cette séquence dans les
  événements Keycloak comme le ferait un analyste SOC.
- Une checklist de mise en production personnelle, écrite par toi, à partir de ce
  que tu as appris dans tout le lab.

**Definition of done** :

- Ton Keycloak est accessible en HTTPS via Traefik avec un certificat valide.
- Tu as restauré une sauvegarde Postgres sur un environnement vierge et retrouvé tes
  realms/utilisateurs intacts.
- Tu as retrouvé et documenté une tentative de brute-force simulée dans les
  événements Keycloak.
- Tu as un document `CHECKLIST-PRODUCTION.md` personnel dans ce dossier.

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

**Extension confirmée** : Keycloak 26.7 (la version utilisée dans ce lab) propose une
API de provisioning **SCIM 2.0** en preview. Une fois midPoint en place comme source
de vérité, teste le provisioning SCIM vers Keycloak en complément (ou en alternative)
du connecteur LDAP déjà utilisé — pour voir concrètement la différence entre les deux
approches de provisioning (SCIM standardisé vs connecteur LDAP propriétaire).

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

## Phase 8 — Observabilité et supervision (Prometheus + Grafana)

**Objectif** : passer d'un lab qui "marche" à une infrastructure qu'on sait
surveiller comme en production — un réflexe d'architecte, pas juste
d'administrateur. Keycloak et OpenFGA exposent déjà des métriques
Prometheus natives (Keycloak : `KC_METRICS_ENABLED=true` activé depuis la
Phase 1, endpoint `http://localhost:9000/metrics`) — cette phase consiste à
les exploiter, pas à les créer.

Ce qu'on construit :

- Prometheus scrutant les endpoints métriques de Keycloak et d'OpenFGA.
- Grafana avec des dashboards concrets : taux de connexions
  réussies/échouées, latence d'émission de token, erreurs de synchronisation
  LDAP, latence des `Check` OpenFGA.
- Un exercice d'alerte simple (ex. alerte si le taux d'échec de login
  dépasse un seuil sur une fenêtre glissante).

**Definition of done** :

- Un dashboard Grafana affiche au moins 3 métriques réelles issues de
  Keycloak (pas des données de démonstration).
- Tu sais expliquer pourquoi l'observabilité fait partie intégrante d'une
  architecture IAM (détection d'anomalies de connexion, dimensionnement,
  respect de SLA) — pas juste "pour faire joli".

---

## Après le plan : pistes pour la suite (architecte confirmé)

Une fois toutes les phases terminées, pistes crédibles pour la suite (non détaillées
ici, à construire au fur et à mesure) :

- Déploiement Kubernetes via le Keycloak Operator officiel (au-delà de Docker
  Compose, pour une vraie haute disponibilité multi-nœuds).
- SCIM en pratique plus poussée (au-delà de la preview Keycloak 26.7).
- FAPI 2.0 (profil de sécurité renforcé pour l'open banking/finance) — niche mais
  recherché dans le secteur bancaire.
- Rate limiting / WAF en amont de Keycloak (Traefik middleware ou solution dédiée)
  pour freiner le brute-force avant même qu'il n'atteigne l'application.
- Zero Trust et bastion d'accès (Teleport, Pomerium) branchés sur le même IdP.
- Étude du client Rust `openfga-client` (vakamo-labs) si tu veux consommer OpenFGA
  depuis une application Rust plutôt qu'en HTTP brut.
- Thèmes personnalisés Keycloak (habillage de l'écran de login aux couleurs d'une
  marque) et extensions SPI (règles métier custom en Java).
- Microsoft Entra Domain Services (vrai AD managé dans le cloud) si tu veux
  comparer avec le Samba4 local de la Phase 2 ter, une fois la Phase 7 en place.

---

## Suivi de progression

Coche au fur et à mesure (édite ce fichier, commit à chaque étape franchie) :

- [x] Phase 0 — Environnement prêt
- [x] Phase 1 — Keycloak core
- [ ] Phase 1 — Extension (Groups, bearer-only, MFA/WebAuthn)
- [x] Phase 2 — LLDAP + fédération
- [ ] Phase 2 bis — OpenLDAP (comparatif, optionnel)
- [ ] Phase 2 ter — Active Directory (Samba4, en cours)
- [x] Phase 3 — OIDC/SAML/tokens
- [ ] Phase 3 — Exercice D (SSO multi-app + Single Logout)
- [x] Phase 4 — OpenFGA (ReBAC)
- [ ] Phase 4 bis — Authentication Flows avancés et durcissement
- [ ] Phase 4 ter — Exploitation production (TLS/backup/clustering/audit)
- [ ] Phase 5 — midPoint (IGA) + extension SCIM
- [ ] Phase 6 — Comparatif Zitadel
- [ ] Phase 7 — Entra ID (fédération hybride)
- [ ] Phase 8 — Observabilité (Prometheus + Grafana)
