# Phase 3 — OIDC, SAML et cycle de vie des tokens en profondeur

Lire avant de commencer : `../docs/fondamentaux/02-oauth2.md`,
`03-oidc.md`, `04-saml2.md`, `09-tokens-jwt-refresh-securite.md`.
Prérequis : Phase 1 démarrée (realm `lab-iam`, clients `demo-spa` et
`demo-backend`, utilisateur `alice`).

Cette phase a trois exercices indépendants. Fais-les dans l'ordre.

---

## Exercice A — Rejouer PKCE à la main (`scripts/`)

Le plus important des trois pour la compréhension en profondeur : voir
littéralement chaque paramètre HTTP.

```bash
cd phase-3-oidc-saml-tokens/scripts
export INTROSPECTION_CLIENT_SECRET="<secret du client demo-backend, phase 1>"
./oidc-flow-curl-demo.sh
```

Le script :

1. Génère `code_verifier` / `code_challenge` (PKCE).
2. T'affiche l'URL d'autorisation à ouvrir dans un navigateur.
3. Te demande de coller l'URL de redirection une fois connecté (une erreur
   "page introuvable" sur `localhost:3000/callback` est normale — rien
   n'écoute là, tu copies juste l'URL depuis la barre d'adresse).
4. Échange le `code` contre les tokens, décode l'ID Token.
5. Effectue un `refresh_token` grant et te montre si la rotation a eu lieu.
6. Introspecte l'access_token (si tu as fourni le secret du client
   `demo-backend`).
7. Révoque le refresh_token et t'invite à vérifier que la révocation
   fonctionne bien.

## Exercice B — Un vrai client OIDC (`demo-app-oidc/`)

Une petite application Express qui fait tourner le même flux, mais avec une
vraie librairie cliente (`openid-client`) — pour voir à quoi ressemble le code
d'une application réelle, pas juste des appels curl.

```bash
cd phase-3-oidc-saml-tokens/demo-app-oidc
cp .env.example .env
# édite OIDC_INTROSPECTION_CLIENT_SECRET avec le secret du client demo-backend
npm install
npm start
```

Ouvre <http://localhost:3000>, clique "Se connecter via Keycloak", connecte-toi
avec `alice`. Tu verras les claims de l'ID Token, et tu pourras déclencher un
refresh et une introspection depuis l'interface.

> Ce code n'est pas un exemple de production : session en mémoire, pas de
> HTTPS, secrets en variables d'environnement en clair. Pour une vraie
> application, voir le pattern BFF (Backend-For-Frontend) mentionné dans
> `../docs/fondamentaux/09-tokens-jwt-refresh-securite.md`.

## Exercice C — SAML sans dépendance externe (Identity Brokering)

Objectif : voir une vraie assertion SAML sans avoir à installer de
librairie SAML tierce, en utilisant deux realms Keycloak l'un contre l'autre.

1. Dans le realm `lab-iam` (celui de la Phase 1), active le protocole SAML sur
   un nouveau client : Clients → Create client → Client type `SAML` →
   Client ID : `saml-sp-realm2`.
   - Valid redirect URIs : `http://localhost:8080/realms/lab-iam-sp/broker/saml-idp/endpoint*`
     (l'URL de callback du broker du second realm, créé à l'étape suivante).
2. Crée un **second realm** : `lab-iam-sp` (celui qui va jouer le rôle de
   Service Provider).
3. Dans `lab-iam-sp` → **Identity providers** → Add provider → `SAML v2.0`.
   - Alias : `saml-idp`.
   - Import depuis l'URL de métadonnées du premier realm :
     `http://localhost:8080/realms/lab-iam/protocol/saml/descriptor`
     (Keycloak remplit automatiquement les endpoints, le certificat de
     signature, etc. — regarde chaque champ rempli, c'est l'équivalent XML
     de ce qui a été décrit dans `04-saml2.md`).
4. Va sur `http://localhost:8080/realms/lab-iam-sp/account`, clique sur le
   bouton de connexion via `saml-idp` : tu es redirigé vers le realm
   `lab-iam` pour t'authentifier (avec `alice`), puis renvoyé vers
   `lab-iam-sp` déjà connecté.
5. Pendant la redirection retour, ouvre les DevTools réseau de ton navigateur
   sur la requête POST vers `/broker/saml-idp/endpoint` : le corps contient un
   champ `SAMLResponse` en base64 — décode-le (ex.
   `echo '<valeur>' | base64 -d | xmllint --format -`) pour lire l'assertion
   XML brute et repérer les éléments décrits dans `04-saml2.md`
   (`Issuer`, `Signature`, `Conditions`, `AttributeStatement`).

## Definition of done de cette phase

- [ ] Tu as exécuté le script curl de bout en bout, y compris la vérification
      de révocation finale.
- [ ] Tu as vu le refresh token rotation se produire (ou son absence, si non
      activé — sais expliquer pourquoi dans les deux cas).
- [ ] Tu as lu au moins une assertion SAML brute et identifié `Issuer`,
      `Signature`, `Conditions`, `AttributeStatement`.

## Suite

→ `../phase-4-openfga-authz/README.md`
