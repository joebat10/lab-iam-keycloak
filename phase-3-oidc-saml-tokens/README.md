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
`lab-iam` joue l'IdP, `lab-iam-sp` (nouveau realm) joue le SP.

**Ordre important** : configure d'abord le broker côté SP (étape 2) — Keycloak
y génère l'URL de callback exacte à utiliser ensuite côté IdP (étape 3),
plutôt que de la deviner à l'avance.

1. Crée un second realm : `lab-iam-sp`.
2. Dans `lab-iam-sp` → **Identity providers** → Add provider → `SAML v2.0`.
   - Alias : au choix (ex. `saml`).
   - Colle l'URL de métadonnées de `lab-iam` dans le champ d'import
     (`SAML entity descriptor` ou "Import from URL" selon la version) :
     `http://localhost:8080/realms/lab-iam/protocol/saml/descriptor`
   - **Add**. Une fois créé, copie le champ **Redirect URI** affiché en haut
     de la page de détail (ex. `.../realms/lab-iam-sp/broker/saml/endpoint`)
     et note le **Service provider entity ID** affiché
     (par défaut `http://localhost:8080/realms/lab-iam-sp`).
3. Dans `lab-iam` → **Clients** → Create client → Client type `SAML`.
   - Client ID : colle exactement le "Service provider entity ID" noté à
     l'étape 2.
   - Valid redirect URIs : colle le "Redirect URI" noté à l'étape 2.
   - **Save**.
4. Va sur `http://localhost:8080/realms/lab-iam-sp/account`, clique sur le
   bouton de connexion via ton alias : tu es redirigé vers `lab-iam` pour
   t'authentifier (avec `alice`), puis renvoyé vers `lab-iam-sp`.
5. Pendant la redirection retour, ouvre les DevTools réseau de ton navigateur
   sur la requête POST vers `/broker/<alias>/endpoint` : le corps contient un
   champ `SAMLResponse` en base64 — décode-le (ex.
   `echo '<valeur>' | base64 -d` dans un terminal) pour lire l'assertion
   XML brute et repérer les éléments décrits dans `04-saml2.md`
   (`Issuer`, `Signature`, `Conditions`, `AttributeStatement`).

### Retour d'expérience : le vrai parcours de debug (3 erreurs, dans l'ordre)

Un client SAML créé **à la main** (plutôt que par import de métadonnées du
SP) ne connaît pas le certificat du SP — ça déclenche une vraie séquence
d'erreurs, chacune corrigeant la précédente :

1. **`Invalid requester`** — `lab-iam` reçoit une requête d'un émetteur qu'il
   ne reconnaît pas → cause : le client SAML de l'étape 3 n'existait pas
   encore, ou son Client ID ne correspondait pas exactement au
   "Service provider entity ID" du broker.
2. **`Invalid signature on document`** (dans les logs Keycloak,
   `SamlProtocolUtils.verifyDocumentSignature`) — `lab-iam` reçoit bien la
   requête, mais elle est signée et Keycloak n'a aucun certificat pour la
   vérifier (normal, le client a été créé sans import de métadonnées) →
   correctif : client SAML → onglet **Keys** (pas Settings — un piège
   d'interface à lui seul) → **Client signature required** → **Off**.
3. **`Invalid signature in response`** (côté navigateur, sur `lab-iam-sp`
   cette fois) — la requête passe, mais l'assertion retournée n'est pas
   signée de façon vérifiable → correctif : client SAML dans `lab-iam` →
   **Sign assertions** → **On** (en plus de `Sign documents` déjà activé).

**Nuance sécurité sur `Client signature required : Off`** : ce toggle ne
protège que la requête *entrante* (l'`AuthnRequest`) — pas la réponse, qui
reste signée (`Sign documents`/`Sign assertions`). L'authentification réelle
n'est jamais contournée : alice doit toujours fournir son vrai mot de passe,
et l'assertion signée n'est envoyée qu'au `Redirect URI` verrouillé. Plusieurs
guides d'intégration SAML réels (Lokalise, Kasm, OpenVPN Access Server)
désactivent aussi ce toggle par défaut, car beaucoup de SP ne signent pas
leurs requêtes — la vraie bonne pratique reste d'importer les métadonnées du
SP plutôt que de créer le client à la main, ce qu'on a volontairement évité
ici pour observer chaque étape séparément.

### Le "First Broker Login" et pourquoi le username est un identifiant illisible

Une fois la signature validée, Keycloak affiche un écran **"Update Account
Information"** avec un username généré (`g-xxxxxxxx-...`) plutôt que
`alice`. C'est normal : Keycloak ne fusionne jamais silencieusement une
identité fédérée avec un compte local (c'est le mécanisme de
**First Broker Login**), et ton client SAML n'envoie que le NameID brut, sans
attributs (email, prénom, nom). En entreprise, c'est exactement le symptôme
qui remonte en support : *"le SSO crée des comptes avec des noms bizarres"*
— la cause est presque toujours l'absence d'**Identity Provider Mappers**
côté broker (`Identity providers → <alias> → Mappers`) pour extraire
proprement les attributs de l'assertion à chaque connexion.

## Definition of done de cette phase

- [x] Tu as exécuté le script curl de bout en bout, y compris la vérification
      de révocation finale.
- [x] Tu as vu le refresh token rotation se produire (ou son absence, si non
      activé — sais expliquer pourquoi dans les deux cas).
- [x] Tu as lu au moins une assertion SAML brute et identifié `Issuer`,
      `Signature`, `Conditions`, `AttributeStatement`.

## Suite

→ `../phase-4-openfga-authz/README.md`
