# OpenID Connect (OIDC) — l'identité par-dessus OAuth2

## L'idée en une phrase

OIDC est une **couche d'identité standardisée construite au-dessus d'OAuth 2.0**.
Il répond à la question qu'OAuth2 laisse ouverte : *qui* s'est authentifié, avec
quelles informations vérifiées (claims), et depuis quand.

## Ce qu'OIDC ajoute concrètement à OAuth2

1. **L'ID Token** : un JWT signé (toujours), qui contient des claims sur
   l'utilisateur (`sub`, `iss`, `aud`, `exp`, `iat`, et éventuellement `name`,
   `email`, etc.). C'est la vraie nouveauté par rapport à OAuth2 pur.
2. **Le endpoint `/userinfo`** : permet de récupérer des informations
   supplémentaires sur l'utilisateur avec l'`access_token`.
3. **Le scope `openid`** : sa seule présence dans la requête d'autorisation
   signale "c'est un flux OIDC, pas juste OAuth2" et déclenche l'émission d'un
   ID Token.
4. **La découverte automatique** : le endpoint
   `/.well-known/openid-configuration` publie tous les endpoints et
   capacités du serveur (essentiel pour que les librairies clientes se
   configurent automatiquement — dans Keycloak :
   `/realms/<realm>/.well-known/openid-configuration`).

## Anatomie d'un ID Token (JWT)

Un JWT a 3 parties séparées par des points : `header.payload.signature`.

```
eyJhbGciOiJSUzI1NiIs...   <- header (algo, kid)
eyJzdWIiOiJhYmMxMjMi...   <- payload (claims)
SflKxwRJSMeKKF2QT4fw...   <- signature (vérifiable via la clé publique du realm)
```

Claims essentiels à savoir lire :

| Claim | Signification |
|---|---|
| `iss` | Issuer — qui a émis le token (l'URL du realm Keycloak) |
| `sub` | Subject — identifiant unique et stable de l'utilisateur |
| `aud` | Audience — pour quel client ce token est destiné |
| `exp` / `iat` | Expiration / Issued At — durée de vie |
| `azp` | Authorized party — le client qui a demandé le token |

**Ne jamais faire confiance à un JWT sans vérifier sa signature** (via les clés
publiques exposées sur `/protocol/openid-connect/certs`) et son `exp` — c'est
l'erreur de sécurité la plus commune chez les développeurs qui implémentent OIDC
"à la main".

## OIDC vs OAuth2 : le résumé qu'il faut savoir donner en entretien

> OAuth2 délègue un **accès** (autorisation). OIDC, construit dessus, prouve une
> **identité** (authentification) via un ID Token standardisé et vérifiable.
> Un `access_token` OAuth2 sert à appeler une API ; un `id_token` OIDC sert à
> prouver qui s'est connecté à l'application elle-même.

## Endpoints Keycloak à connaître (remplacer `<realm>`)

- Découverte : `GET /realms/<realm>/.well-known/openid-configuration`
- Autorisation : `GET /realms/<realm>/protocol/openid-connect/auth`
- Token : `POST /realms/<realm>/protocol/openid-connect/token`
- Userinfo : `GET /realms/<realm>/protocol/openid-connect/userinfo`
- Introspection : `POST /realms/<realm>/protocol/openid-connect/token/introspect`
- Logout : `POST /realms/<realm>/protocol/openid-connect/logout`
- Clés publiques (JWKS) : `GET /realms/<realm>/protocol/openid-connect/certs`

Tu manipuleras concrètement chacun de ces endpoints en Phase 3.
