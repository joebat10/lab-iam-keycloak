# Phase 1 — Keycloak seul : le socle SSO/IdP

Lire avant de commencer : `../docs/fondamentaux/01-bases-iam-authn-vs-authz.md`,
`02-oauth2.md`, `03-oidc.md`.

## Démarrer la stack

```bash
cd phase-1-keycloak-core
cp .env.example .env        # puis édite les mots de passe
docker compose up -d
docker compose logs -f keycloak   # attends la ligne "Keycloak ... started in ..."
```

Vérifie la santé du conteneur (le endpoint santé est sur le port 9000 depuis
Keycloak 26, pas 8080) :

```bash
curl -sf http://localhost:9000/health/ready && echo OK
```

Console admin : <http://localhost:8080> → login avec les identifiants de ton
`.env` (`KC_BOOTSTRAP_ADMIN_USERNAME` / `KC_BOOTSTRAP_ADMIN_PASSWORD`).

> ⚠️ Ce compose utilise `start-dev`, adapté à l'apprentissage : base de données
> réelle (Postgres, contrairement au H2 mémoire du mode dev par défaut) mais
> TLS désactivé et hostname non strict. **Ne jamais exposer cette
> configuration sur Internet telle quelle.** Le passage en mode
> `start --optimized` + TLS + reverse proxy sera abordé plus tard (voir la fin
> de `ROADMAP.md`).

## Étape 1 — Créer un realm dédié

Ne travaille **jamais** dans le realm `master` (réservé à l'administration de
Keycloak lui-même) :

1. Menu de gauche → sélecteur de realm → **Create Realm**.
2. Nom : `lab-iam` (garde ce nom, les phases suivantes s'y réfèrent).
3. Enabled : ON.

## Étape 2 — Créer un client "confidential" (backend)

Un client confidentiel détient un secret et peut donc être digne de confiance
pour des opérations sensibles (ex. un backend qui appelle le grant
`client_credentials`).

1. Clients → Create client.
2. Client ID : `demo-backend`.
3. Client authentication : **On** (ceci en fait un client confidentiel).
4. Authentication flow : coche `Standard flow` (Authorization Code) et
   `Service accounts roles` (Client Credentials).
5. Une fois créé, onglet **Credentials** → note le `Client secret` généré.

## Étape 3 — Créer un client "public" (SPA)

1. Clients → Create client.
2. Client ID : `demo-spa`.
3. Client authentication : **Off** (client public — pas de secret, PKCE
   obligatoire pour compenser).
4. Valid redirect URIs : `http://localhost:3000/*` (utilisé en Phase 3 pour
   l'application de démo Node.js).
5. Web origins : `http://localhost:3000`.

**Pourquoi cette distinction compte** : un client public ne peut PAS garder de
secret (son code tourne dans le navigateur, donc inspectable). PKCE compense
cette absence de secret en liant cryptographiquement la demande de code à
l'échange de token. Un client confidentiel, lui, peut garder un secret côté
serveur — c'est ce secret qui l'authentifie, en plus ou à la place de PKCE.

## Étape 4 — Créer un utilisateur de test

1. Users → Add user. Username : `alice`. Email : `alice@lab-iam.local`.
2. Onglet **Credentials** → Set password : décoche "Temporary" pour un mot de
   passe permanent en lab (en prod, on laisserait "Temporary" ON pour forcer
   un changement au premier login).

## Étape 5 — Rôles realm vs rôles client

1. Realm roles → Create role : `app-user`.
2. Assigne ce rôle à `alice` (Users → alice → Role mapping → Assign role).
3. Regarde aussi **Clients → demo-backend → Roles** : ici tu peux créer un
   rôle *spécifique à ce client* (ex. `backend-admin`), invisible des autres
   clients. C'est la différence clé : un rôle realm est global au realm, un
   rôle client n'a de sens que pour l'application qui le définit.

## Étape 6 — Observer un premier flux OIDC réel

Keycloak fournit une "Account Console" par realm qui te sert de premier client
de test sans rien coder :

```
http://localhost:8080/realms/lab-iam/account
```

Connecte-toi avec `alice`. Regarde `docker compose logs -f keycloak` pendant
la connexion : tu verras les échanges. Puis va sur

```
http://localhost:8080/realms/lab-iam/.well-known/openid-configuration
```

et repère les endpoints listés dans `../docs/fondamentaux/03-oidc.md`.

## Étape 7 — Exporter le realm (ton premier artefact versionné)

```bash
docker compose exec keycloak /opt/keycloak/bin/kc.sh export \
  --realm lab-iam \
  --file /opt/keycloak/data/import/lab-iam-realm.json \
  --users realm_file
```

Le fichier apparaît dans `./realm-export/lab-iam-realm.json` sur ta machine
(volume monté). **Commit-le dans Git** : c'est la preuve versionnée de ta
configuration, et grâce à `--import-realm` dans le `docker-compose.yml`, il
sera automatiquement réimporté au prochain démarrage d'un environnement propre
— exactement le principe d'Infrastructure as Code appliqué à l'IAM.

> Le fichier exporté contient normalement les hash de mots de passe, pas les
> mots de passe en clair — vérifie tout de même son contenu avant de le
> commiter si tu changes les valeurs par défaut de ce lab.

## Definition of done de cette phase

- [ ] Realm `lab-iam` créé, jamais touché à `master`.
- [ ] Un client confidentiel et un client public créés, et tu sais expliquer
      pourquoi PKCE compense l'absence de secret du client public.
- [ ] Un utilisateur `alice` avec au moins un rôle realm.
- [ ] Tu as vu et lu le JSON de `/.well-known/openid-configuration`.
- [ ] `realm-export/lab-iam-realm.json` commité dans Git.

## Suite

→ `../phase-2-lldap-federation/README.md`
