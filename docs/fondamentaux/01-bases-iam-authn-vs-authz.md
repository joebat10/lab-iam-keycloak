# Bases de l'IAM : authentification vs autorisation

## Les deux questions que tout système IAM doit répondre

1. **Authentification (AuthN)** — *Qui es-tu ?* Vérifier qu'une identité est bien
   celle qu'elle prétend être (mot de passe, MFA, certificat, biométrie...).
2. **Autorisation (AuthZ)** — *Qu'as-tu le droit de faire ?* Une fois l'identité
   vérifiée, décider si elle peut accéder à telle ressource ou effectuer telle
   action.

C'est la confusion n°1 chez les débutants : OAuth 2.0, par exemple, est un
protocole **d'autorisation** (délégation d'accès), pas d'authentification — d'où
la nécessité d'OpenID Connect pour ajouter une vraie couche d'identité (voir
`03-oidc.md`).

## Les briques d'un système IAM complet

| Brique | Rôle | Exemple dans ce lab |
|---|---|---|
| Annuaire (Directory) | Stocke les identités (utilisateurs, groupes) | LLDAP (phase 2) |
| IdP / SSO | Authentifie et émet des tokens/assertions | Keycloak (phase 1) |
| Autorisation fine | Décide des permissions détaillées | OpenFGA (phase 4) |
| Gouvernance (IGA) | Gère le cycle de vie et la conformité des accès | midPoint (phase 5) |
| MFA / facteurs additionnels | Renforce l'authentification | WebAuthn, OTP (voir `07-mfa-webauthn.md`) |

Une erreur fréquente de débutant est de croire qu'un seul outil (souvent l'IdP)
fait tout. En réalité, une architecture IAM mature sépare ces responsabilités —
c'est exactement la logique de ce projet, phase après phase.

## Le cycle de vie d'une identité (Identity Lifecycle)

C'est la vision "architecte" par opposition à la vision "administrateur" :

1. **Joiner** — création du compte (arrivée d'un salarié, inscription d'un client).
2. **Mover** — changement de rôle, de service, de périmètre d'accès.
3. **Leaver** — désactivation, révocation des accès, archivage.

Ce triptyque **Joiner-Mover-Leaver (JML)** est au cœur de la Phase 5 (midPoint) :
un IdP comme Keycloak sait authentifier un compte, mais ne sait généralement pas
répondre tout seul à "pourquoi ce compte existe-t-il, et qui a approuvé son accès
à telle ressource ?" — c'est le rôle d'une plateforme IGA.

## SSO : Single Sign-On

Le SSO permet à un utilisateur de s'authentifier **une seule fois** auprès d'un
IdP central, puis d'accéder à plusieurs applications ("Service Providers" ou
"Relying Parties") sans se ré-authentifier. Techniquement, cela repose sur :

- une **session** côté IdP (cookie de session sur le domaine de l'IdP),
- des **tokens ou assertions** que chaque application peut vérifier
  indépendamment (JWT en OIDC, assertion XML signée en SAML).

Le SSO est la raison d'être de Keycloak dans ce lab : un realm = un domaine de
confiance, plusieurs clients = plusieurs applications qui font confiance au même
realm.

## IdP vs SP (ou "Relying Party")

- **Identity Provider (IdP)** : l'autorité qui authentifie et vantage l'identité
  (Keycloak dans ce lab).
- **Service Provider (SP)** en SAML / **Relying Party (RP)** en OIDC : l'application
  qui fait confiance à l'IdP et consomme le token/l'assertion pour laisser entrer
  l'utilisateur.

## Identity Brokering / Fédération

Keycloak peut lui-même agir comme SP/RP vis-à-vis d'un autre IdP (Google, un autre
Keycloak, un fournisseur d'entreprise) — c'est l'"Identity Brokering". C'est ce
mécanisme qu'on utilise en Phase 3 pour l'exercice SAML réalisé uniquement avec
deux realms Keycloak.

## Pour aller plus loin dans ce dépôt

- Autorisation en détail (RBAC/ABAC/ReBAC) → `08-autorisation-rbac-abac-rebac.md`
- Le protocole qui porte l'autorisation déléguée → `02-oauth2.md`
- La couche d'identité au-dessus → `03-oidc.md`
