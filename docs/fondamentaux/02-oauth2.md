# OAuth 2.0 — délégation d'autorisation

## Ce qu'OAuth2 est vraiment

OAuth 2.0 (RFC 6749) est un protocole de **délégation d'autorisation** : il permet
à une application (le *client*) d'obtenir un accès limité à une ressource, au nom
d'un utilisateur, **sans jamais voir son mot de passe**.

Ce n'est **pas** un protocole d'authentification à l'origine — il ne dit rien sur
"qui" s'est connecté, seulement "cette application a le droit d'accéder à telle
ressource, avec telle portée (scope), pendant tel temps".

## Les quatre rôles

| Rôle | Définition | Dans ce lab |
|---|---|---|
| Resource Owner | L'utilisateur, propriétaire de ses données | L'utilisateur de test créé en phase 1 |
| Client | L'application qui demande l'accès | Le client OIDC de la phase 3 |
| Authorization Server | Émet les tokens | Keycloak |
| Resource Server | L'API qui vérifie le token et sert la ressource | À imaginer / simuler dans les exercices |

## Les grant types (flux) à connaître absolument

### Authorization Code (+ PKCE) — **le seul à utiliser pour un utilisateur humain**

1. Le client redirige l'utilisateur vers l'Authorization Server avec un
   `code_challenge` (PKCE).
2. L'utilisateur s'authentifie (login Keycloak).
3. L'Authorization Server redirige vers le client avec un `code` à usage unique.
4. Le client échange ce `code` (+ `code_verifier`) contre un `access_token`
   (et un `refresh_token`) sur un canal serveur-à-serveur.

**PKCE (Proof Key for Code Exchange, RFC 7636)** est aujourd'hui **obligatoire**
même pour les clients confidentiels (recommandation OAuth 2.1) : il empêche
qu'un `code` intercepté soit rejouable par un attaquant qui n'a pas le
`code_verifier` d'origine. On le manipule à la main dans le script de la
Phase 3 pour bien comprendre pourquoi ça marche.

### Client Credentials — **machine-to-machine, pas d'utilisateur**

Un service backend s'authentifie directement avec son `client_id` /
`client_secret` pour obtenir un token en son nom propre (pas au nom d'un
utilisateur). Utile pour des jobs batch, des intégrations service-à-service.

### Refresh Token — **renouveler sans ré-authentifier**

Voir `09-tokens-jwt-refresh-securite.md` pour le détail : le point clé est que
le refresh token permet d'obtenir un nouvel `access_token` (court-vécu) sans
redemander le mot de passe, tant que la session/refresh token est encore valide
et non révoqué.

### Ce qu'il ne faut (plus) utiliser

- **Implicit Grant** : obsolète, retiré d'OAuth 2.1 — le token transitait dans
  l'URL (fragment), exposé aux logs et à l'historique navigateur.
- **Resource Owner Password Credentials (ROPC)** : le client voit le mot de passe
  de l'utilisateur — à éviter sauf cas très spécifiques et de confiance totale
  (ex. migration legacy).

## Scopes

Un *scope* définit la portée de l'accès demandé (`read:documents`,
`profile`, `email`...). Le client demande des scopes, l'utilisateur (ou une
politique d'entreprise) les valide, et l'`access_token` final n'embarque que
les scopes accordés — jamais plus que demandé, jamais plus que permis.

## Ce qu'OAuth2 ne fait PAS

- Il ne définit pas de format standard pour dire "qui" est l'utilisateur.
- Il ne définit pas de mécanisme standard de "logout" fédéré.
- Il ne dit rien sur le format du token (à part quelques recommandations) — un
  `access_token` OAuth2 pur peut être opaque (juste une chaîne aléatoire côté
  serveur) ou un JWT, selon l'implémentation.

C'est précisément ce manque que comble OpenID Connect → `03-oidc.md`.
