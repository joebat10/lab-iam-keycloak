# Phase 2 — Fédération d'annuaire avec LLDAP

Lire avant de commencer : `../docs/fondamentaux/06-ldap-annuaires.md`.
Prérequis : la Phase 1 doit être démarrée (`docker compose up -d` dans
`phase-1-keycloak-core/`) — ce compose rejoint son réseau Docker.

## Démarrer LLDAP

```bash
cd phase-2-lldap-federation
cp .env.example .env
openssl rand -base64 32   # colle le résultat dans LLDAP_JWT_SECRET
openssl rand -base64 32   # colle le résultat dans LLDAP_KEY_SEED
docker compose up -d
```

Interface d'administration LLDAP : <http://localhost:17170>
Login initial : `admin` / la valeur de `LLDAP_ADMIN_PASSWORD` de ton `.env`.

## Étape 1 — Créer un utilisateur et un groupe dans LLDAP

1. Dans l'UI LLDAP : Users → Create a user. Ex. `bob` / `bob@lab-iam.local`.
2. Groups → Create a group, ex. `lab-users`, puis ajoute `bob` dedans.

C'est volontairement l'inverse de la Phase 1 : `alice` a été créée **dans**
Keycloak, `bob` est créé **dans l'annuaire**, et n'existera dans Keycloak
qu'après fédération — c'est exactement la différence que tu dois pouvoir
expliquer en entretien.

## Étape 2 — Configurer la fédération côté Keycloak

Dans la console admin Keycloak (realm `lab-iam`) :

1. **User federation** → Add provider → `ldap`.
2. **Connection settings** :
   - Connection URL : `ldap://lldap:3890` (nom du service Docker, résolu via
     le réseau partagé — pas `localhost`, qui pointerait vers le conteneur
     Keycloak lui-même).
   - Bind type : `simple`.
   - Bind DN : `uid=admin,ou=people,dc=lab-iam,dc=local` (adapte au
     `LLDAP_BASE_DN` choisi).
   - Bind credential : le mot de passe admin LLDAP.
3. **LDAP searching and updating** :
   - Users DN : `ou=people,dc=lab-iam,dc=local`.
   - Username LDAP attribute : `uid`.
   - RDN LDAP attribute : `uid`.
   - UUID LDAP attribute : `entryUUID` (attribut standard exposé par LLDAP).
   - Edit mode : `READ_ONLY` pour ce lab (Keycloak ne modifie jamais LLDAP —
     réflexe de sécurité par défaut sain).
4. Bouton **Test connection**, puis **Test authentication** avant de
   sauvegarder — Keycloak te dira immédiatement si le bind échoue.
5. Une fois sauvegardé : onglet **Synchronization** → **Sync all users**.

## Étape 3 — Vérifier

Users → tu dois voir apparaître `bob`, avec une petite icône indiquant qu'il
est **fédéré** (géré par LDAP), différente de `alice` (gérée localement par
Keycloak). Connecte-toi avec `bob` sur l'Account Console
(`http://localhost:8080/realms/lab-iam/account`) — le mot de passe vérifié est
celui défini dans LLDAP, jamais stocké côté Keycloak.

## Étape 4 — Mapper des attributs et des groupes

Dans le provider LDAP → onglet **Mappers**, ajoute un mapper `group-ldap-mapper`
pointant vers `ou=groups,dc=lab-iam,dc=local` pour que le groupe `lab-users`
de LLDAP devienne un **groupe Keycloak** utilisable dans les Role mappings —
c'est ainsi qu'on relie l'appartenance à un groupe d'annuaire à des rôles
applicatifs.

## Definition of done de cette phase

- [ ] Tu sais expliquer bind DN, base DN, et pourquoi `READ_ONLY` est le choix
      par défaut le plus sûr.
- [ ] `bob` existe dans LLDAP et se connecte via Keycloak sans jamais avoir été
      créé manuellement dans la console Keycloak.
- [ ] Le groupe `lab-users` de LLDAP est visible côté Keycloak.

## Suite

→ `../phase-3-oidc-saml-tokens/README.md`
