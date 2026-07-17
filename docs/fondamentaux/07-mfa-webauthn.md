# MFA et WebAuthn

## Pourquoi le mot de passe seul ne suffit plus

Un facteur unique (mot de passe) est vulnérable au phishing, à la réutilisation
de mots de passe, au credential stuffing. Le **MFA (Multi-Factor
Authentication)** ajoute un ou plusieurs facteurs indépendants :

| Catégorie | Exemple |
|---|---|
| Ce que tu sais | Mot de passe, code PIN |
| Ce que tu as | Téléphone (OTP par SMS/app), clé de sécurité physique (YubiKey) |
| Ce que tu es | Biométrie (empreinte, visage) |

## TOTP (Time-based One-Time Password)

Le mécanisme MFA le plus répandu (Google Authenticator, Keycloak "OTP") :
un secret partagé entre le serveur et l'app d'authentification génère un code
à 6 chiffres qui change toutes les 30 secondes, dérivé de l'heure courante et
du secret (HMAC-SHA1 la plupart du temps, RFC 6238). Facile à activer côté
Keycloak dans les "Required Actions" d'un realm.

## WebAuthn : au-delà du MFA classique

**WebAuthn** (standard W3C, porté par la FIDO Alliance) va plus loin que le
simple "second facteur" : il permet une authentification **sans mot de passe**
basée sur de la cryptographie à clé publique.

Principe :

1. À l'enregistrement, le navigateur/l'appareil génère une **paire de clés**
   (privée/publique) spécifique au site.
2. La **clé privée ne quitte jamais l'appareil** (souvent protégée par un
   enclave matérielle ou par biométrie locale).
3. La **clé publique** est envoyée et stockée côté serveur (Keycloak).
4. À chaque connexion, le serveur envoie un challenge aléatoire ; l'appareil le
   signe avec la clé privée ; le serveur vérifie la signature avec la clé
   publique stockée.

Conséquence de sécurité majeure : **il n'y a rien à voler côté serveur** qui
permettrait de se faire passer pour l'utilisateur (contrairement à une base de
mots de passe, même hashés) — et **rien de "phishable"**, car la signature est
liée cryptographiquement au domaine d'origine (`origin`), donc un faux site
imitant l'IdP ne peut pas obtenir de signature valide.

## Passkeys

Les "Passkeys" sont, en pratique, du WebAuthn avec une expérience utilisateur
simplifiée et une **synchronisation multi-appareils** gérée par l'écosystème
(Apple iCloud Keychain, Google Password Manager...) — la clé privée est
répliquée de façon sécurisée entre les appareils d'un même utilisateur, ce qui
lève l'obstacle historique du WebAuthn ("je perds mon téléphone, je perds mon
accès").

## Ce qu'il faut retenir pour ce lab

- Le MFA (TOTP) est activable directement dans Keycloak sans aucune
  configuration externe — bon premier exercice en Phase 1/3.
- WebAuthn nécessite un contexte sécurisé (HTTPS, ou `localhost` qui est
  considéré comme sécurisé par les navigateurs) — à garder en tête si tu
  pousses ce lab au-delà de `localhost`.
- MFA et WebAuthn se configurent au niveau du realm dans Keycloak
  (Authentication → Required Actions / Policies).
