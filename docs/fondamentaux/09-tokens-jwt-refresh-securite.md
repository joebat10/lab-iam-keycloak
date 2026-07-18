# Tokens, refresh et sécurité opérationnelle

## Les trois tokens qu'émet Keycloak après un login OIDC

| Token | Rôle | Durée de vie typique |
|---|---|---|
| `id_token` | Preuve d'identité (claims sur l'utilisateur), destiné au client | Courte, à usage unique côté client au moment du login |
| `access_token` | Autorise l'appel à une API/ressource | Courte (souvent 1 à 15 min) |
| `refresh_token` | Permet d'obtenir un nouveau `access_token` sans ré-authentifier | Plus longue (minutes à jours), parfois glissante |

Le principe de sécurité central : **plus un token est puissant (peut obtenir
d'autres tokens), plus sa durée de vie doit être courte et son usage restreint**
— le `refresh_token` est le plus sensible des trois, car sa fuite permet de
générer indéfiniment de nouveaux `access_token`.

## Pourquoi des access tokens courts ET des refresh tokens

Sans refresh token, un `access_token` de courte durée forcerait l'utilisateur à
se ré-authentifier (mot de passe) toutes les quelques minutes — inutilisable.
Le refresh token permet de renouveler silencieusement l'access token en
arrière-plan, **sans redemander le mot de passe**, tout en gardant les access
tokens individuels à courte durée de vie (donc peu dangereux s'ils fuitent,
puisqu'ils expirent vite).

## Le grant `refresh_token`

POST /realms/<realm>/protocol/openid-connect/token
Content-Type: application/x-www-form-urlencoded

grant_type=refresh_token
&client_id=<client_id>
&refresh_token=<refresh_token précédent>

Réponse : un nouvel `access_token` (et souvent un nouveau `refresh_token` —
voir *rotation* ci-dessous).

## Refresh Token Rotation

Bonne pratique (et comportement par défaut de nombreux IdP modernes, dont
Keycloak selon la politique du client) : à **chaque** utilisation d'un refresh
token, l'ancien est invalidé et un **nouveau** refresh token est émis. Cela
permet de détecter un vol de token : si un attaquant vole un refresh token et
l'utilise après le client légitime (ou vice-versa), le second usage du même
token périmé peut être détecté et déclencher la révocation de toute la chaîne
(*refresh token reuse detection*).

## Révocation et introspection

- **Introspection** (`/token/introspect`, RFC 7662) : demander au serveur
  d'autorisation si un token est toujours valide — indispensable pour les
  tokens **opaques** (non auto-porteurs), et utile même pour un JWT si on veut
  vérifier une révocation côté serveur (un JWT signé reste "valide"
  cryptographiquement jusqu'à son `exp`, même si le serveur l'a révoqué entre
  temps — d'où l'intérêt de vérifier aussi côté serveur pour les opérations
  sensibles).
- **Révocation** (`/logout` avec le refresh token, ou `/revoke` RFC 7009) :
  invalider un refresh token (et donc couper la capacité à renouveler) avant
  son expiration naturelle — typiquement au logout, ou en cas de compromission
  détectée.

## `aud` vs `azp` : pourquoi une introspection peut échouer sur un token valide

Piège rencontré en pratique dans ce lab, qui mérite sa propre section tant il
est mal compris : **un token parfaitement valide et non expiré peut recevoir
`{"active": false}` à l'introspection** — sans que ce soit un bug.

- **`azp`** (authorized party) dit *qui a demandé* le token — le client public
  ou confidentiel qui a initié le flux (ex. `demo-spa`).
- **`aud`** (audience) dit *à qui ce token s'adresse* — les ressources censées
  l'accepter. Par défaut, Keycloak ne place dans `aud` que ce qui a été
  explicitement mappé (souvent juste `account`) — **pas automatiquement le
  client qui a demandé le token** (`azp`).

Depuis un correctif de sécurité (CVE-2026-37979, Keycloak ≥ 26.6.2),
l'endpoint `/token/introspect` **exige que le client qui introspecte soit
lui-même présent dans le `aud` du token** — pas seulement qu'il soit un client
authentifié valide du même realm. Un client absent de `aud` reçoit
`{"active": false}`, sans détail supplémentaire (conforme à la RFC 7662, qui
recommande de ne rien révéler à un tiers non concerné par le token).

Conséquence pratique : si un client backend doit pouvoir introspecter des
tokens émis pour un autre client (ex. une API qui vérifie des tokens émis à un
frontend SPA), il faut explicitement ajouter ce backend dans `aud` via un
*audience mapper* sur le client émetteur ou son client scope — ce n'est
jamais implicite.

## JWT auto-porteur vs token opaque : le compromis

| | JWT auto-porteur | Token opaque |
|---|---|---|
| Vérification | Locale (signature), pas d'appel réseau | Nécessite un appel d'introspection au serveur |
| Révocation immédiate | Difficile (le JWT reste valide jusqu'à `exp`) | Immédiate (le serveur peut invalider à tout moment) |
| Performance à grande échelle | Excellente (pas d'aller-retour réseau) | Coût d'un appel réseau par vérification |
| Taille | Plus volumineux (contient les claims) | Compact (juste un identifiant) |

Keycloak permet de configurer les deux approches selon le client et les
exigences de sécurité (durée de vie courte + JWT est souvent un bon compromis
pour la majorité des cas ; token opaque + introspection pour des exigences de
révocation immédiate strictes, ex. secteur bancaire).

## Bonnes pratiques à connaître (et à justifier)

1. **PKCE obligatoire** même pour les clients confidentiels (OAuth 2.1).
2. **Ne jamais stocker un `access_token` ou `refresh_token` dans le
   `localStorage`** d'un navigateur (vulnérable au XSS) — préférer un cookie
   `HttpOnly`, `Secure`, `SameSite` géré côté serveur (pattern BFF —
   Backend-For-Frontend).
3. **Toujours vérifier `aud` et `iss`** d'un JWT, pas seulement sa signature —
   un token valide émis pour une autre application ne doit pas être accepté.
4. **Durées de vie courtes pour les access tokens** (quelques minutes), plus
   longues mais bornées pour les refresh tokens, avec rotation activée.
5. **Toujours révoquer au logout** — ne jamais se contenter d'oublier le token
   côté client sans appeler `/logout` côté serveur.

## Exercice pratique de ce lab (Phase 3)

Le script `phase-3-oidc-saml-tokens/scripts/oidc-flow-curl-demo.sh` rejoue à la
main : génération PKCE → authorization code → échange de token → décodage du
JWT → refresh → introspection → révocation. C'est la meilleure façon de faire
disparaître toute confusion sur ce sujet : voir chaque appel HTTP, chaque
paramètre, chaque réponse brute.

**Retour d'expérience** : lors de ce lab, l'introspection avec le client
`demo-backend` a renvoyé `{"active": false}` sur un token pourtant valide et
non expiré, émis via `demo-spa`. Cause : `demo-backend` n'était pas présent
dans le `aud` du token (voir section `aud` vs `azp` ci-dessus) — pas un bug,
un comportement de sécurité voulu depuis Keycloak 26.6.2.
