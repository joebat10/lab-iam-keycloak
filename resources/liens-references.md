# Ressources externes utilisées pour construire ce projet

Analyse des liens fournis au démarrage du projet, avec le rôle de chaque
ressource dans le plan (`ROADMAP.md`) et quelques correctifs.

## Formation Keycloak — blog Stéphane Robert

<https://blog.stephane-robert.info/docs/services/identite/keycloak/formation/>

Sert de fil conducteur pour la structure pédagogique : le site organise l'IAM en
"Fondamentaux IAM" (bases de l'IAM, autorisation RBAC/ABAC/ReBAC, OAuth2, OIDC,
SAML2, SCIM, LDAP, MFA/WebAuthn, sécurité opérationnelle) puis "Outils"
(authentik, LLDAP, Keycloak avec un plan de formation dédié : installation,
administration). `docs/fondamentaux/` et le découpage en phases de ce dépôt
reprennent volontairement cette logique, en l'étendant avec les briques
supplémentaires ci-dessous.

## LLDAP — blog Stéphane Robert

<https://blog.stephane-robert.info/docs/services/identite/lldap/>

LLDAP (Light LDAP) : annuaire LDAP minimaliste écrit en Rust, pensé pour
l'auto-hébergement (interface web simple, faible empreinte). Utilisé en
**Phase 2** comme source d'identité fédérée dans Keycloak, en remplacement d'un
OpenLDAP ou d'un Active Directory plus lourds à opérer pour un lab personnel.

## OpenFGA — client Rust (vakamo-labs) et documentation officielle

<https://github.com/vakamo-labs/openfga-client>
<https://openfga.dev/docs/getting-started/setup-openfga/configure-openfga>

OpenFGA est un moteur d'autorisation fine inspiré du papier Google Zanzibar
(ReBAC — Relationship-Based Access Control). Utilisé en **Phase 4** pour montrer
la séparation moderne authentification (Keycloak) / autorisation fine (OpenFGA).
Le client `openfga-client` de vakamo-labs est un client gRPC type-safe pour
Rust — une piste pour la suite si tu veux consommer OpenFGA depuis une
application Rust plutôt qu'en HTTP/JSON brut (voir fin de `ROADMAP.md`).
La doc officielle confirme qu'OpenFGA supporte l'authentification OIDC en
entrée, ce qui permet de le brancher directement sur un realm Keycloak comme
émetteur de confiance.

## midPoint (Evolveum)

<https://github.com/evolveum/midpoint>

Plateforme d'**Identity Governance and Administration (IGA)** : provisioning,
réconciliation, workflows d'approbation, RBAC avancé, connecteurs ConnId.
Utilisé en **Phase 5** pour introduire la gouvernance des identités, distincte
de l'IdP/SSO (Keycloak). C'est la brique qui fait la différence entre un profil
"administrateur Keycloak" et un profil "architecte IAM" capable de raisonner sur
tout le cycle de vie d'une identité.

## Playlist YouTube "MidPoint Tutorials"

<https://www.youtube.com/playlist?list=PLUMkpGpxB09_Ag-Wps2lo1BYM6DcOAOBo>

Confirmé : playlist officielle de tutoriels sur midPoint, en partie basée sur le
livre *Practical Identity Management with midPoint*. Bon complément vidéo pour
la Phase 5, en particulier pour visualiser l'interface d'administration avant
de la manipuler soi-même.

## Zitadel

<https://github.com/zitadel/zitadel>

Plateforme IAM open-source moderne (Go, Postgres, architecture event-sourcée),
API-first, avec un modèle de multi-tenance natif (organisations/projets) pensé
dès le départ — contrairement aux realms Keycloak, plus proches d'un modèle
"un realm = une organisation" avec des limites de scalabilité connues à
très grande échelle. Utilisé en **Phase 6** comme point de comparaison
architecturale, pas comme remplacement de Keycloak dans ce lab.

## ⚠️ Correctif : "midpoint-institute.eu"

<https://www.midpoint-institute.eu/en/home>

Ce lien **n'a aucun rapport avec l'IAM**. C'est le site du "MIDPOINT Institute",
un incubateur européen pour professionnels du cinéma et des séries (développement
de scénarios, Prague). Probable confusion de nom avec le vrai midPoint
(Evolveum) — les ressources utiles pour midPoint sont plutôt :

- Documentation officielle : <https://docs.evolveum.com/midpoint/>
- Site produit : <https://evolveum.com/midpoint/>
- La playlist YouTube ci-dessus (celle-là est bien la bonne).

Je le signale explicitement pour éviter de perdre du temps dessus — mais je le
garde dans ce fichier pour mémoire, au cas où tu avais une autre intention en
le partageant.

## Sources ajoutées après comparaison avec un programme de formation professionnelle

**Programme "Keycloak, mise en oeuvre d'une gestion centralisée des accès
utilisateurs"** (Cegos, réf. SR214, PDF fourni par l'utilisateur) : comparatif direct
avec ce lab qui a révélé plusieurs trous à combler (SSO multi-app + Single Logout,
MFA/WebAuthn en pratique, Groups natifs, client bearer-only, durcissement,
TLS/sauvegarde/clustering/audit) — voir les Phases 1 (extension), 3 (Exercice D),
4 bis et 4 ter du `ROADMAP.md`, ajoutées suite à cette analyse.

<https://tech-insider.org/fr/keycloak-tutoriel-sso-open-source-2026/> — tutoriel
Docker Compose détaillé, confirme la recette Traefik + TLS + KC_PROXY_HEADERS
utilisée en Phase 4 ter, et une bonne table de dépannage des erreurs courantes.

<https://www.zerodaycyberacademy.com/ressources/iam-identite-acces/qu-est-ce-que-keycloak>
— article de référence sur l'architecture Keycloak (realms/clients/flows), les 7
contrôles de durcissement standards (repris en Phase 4 bis) et un comparatif
Keycloak vs alternatives (Authentik, Auth0, Okta, Entra ID, Ory).
