# LDAP et annuaires

## Pourquoi un annuaire existe encore en 2026

Avant même OAuth2, OIDC ou SAML, il faut bien stocker les identités *quelque
part*. LDAP (Lightweight Directory Access Protocol) est le standard historique
pour ça : un protocole d'interrogation et de modification d'un annuaire
hiérarchique, extrêmement répandu en entreprise (Active Directory en est
l'implémentation la plus connue côté Microsoft).

Un IdP moderne comme Keycloak **ne remplace pas** un annuaire : il vient
généralement *devant*, en s'y connectant en lecture (parfois écriture) via
une fonctionnalité de **User Federation**.

## Le modèle de données LDAP

Un annuaire LDAP est un arbre. Chaque nœud est une **entrée**, identifiée par un
**DN (Distinguished Name)**, unique dans l'arbre :

```
dc=example,dc=com                              <- racine (domain component)
 └─ ou=people                                  <- unité organisationnelle
     └─ uid=alice,ou=people,dc=example,dc=com  <- une entrée utilisateur
 └─ ou=groups
     └─ cn=admins,ou=groups,dc=example,dc=com  <- une entrée groupe
```

Vocabulaire à maîtriser :

| Terme | Signification |
|---|---|
| `dc` | Domain Component — fragment de domaine (`dc=example,dc=com`) |
| `ou` | Organizational Unit — dossier logique |
| `cn` | Common Name |
| `uid` | User ID |
| `dn` | Distinguished Name — le "chemin complet" unique d'une entrée |
| Bind | L'opération d'authentification contre l'annuaire (simple bind = login + mot de passe) |
| Base DN | Le point de départ des recherches (souvent la racine du domaine) |

## Bind anonyme vs bind applicatif

Une application (comme Keycloak) qui veut interroger l'annuaire pour vérifier
un mot de passe ou lister des utilisateurs a besoin d'un **compte de service**
avec ses propres identifiants (le "bind DN" applicatif) — jamais de bind
anonyme en production.

## LDAP vs LDAPS

- **LDAP** (port 389) : non chiffré par défaut — à ne jamais exposer tel quel
  hors d'un réseau de confiance strict.
- **LDAPS** (port 636) : LDAP sur TLS.
- **StartTLS** : upgrade la connexion LDAP standard vers TLS après une
  négociation initiale.

## LLDAP : pourquoi ce choix dans ce lab plutôt qu'OpenLDAP

OpenLDAP est puissant mais notoirement pénible à configurer pour un débutant
(schémas LDIF, `slapd.conf`, ACL complexes). **LLDAP** (utilisé en Phase 2)
assume volontairement un périmètre plus restreint : gestion d'utilisateurs et
de groupes, interface web simple, écrit en Rust, pensé pour l'auto-hébergement
personnel. Il n'implémente pas tout LDAP (ce n'est pas un annuaire "généraliste"),
mais couvre exactement ce dont un IdP a besoin pour l'authentification et les
groupes — un choix pédagogique délibéré pour se concentrer sur la fédération
plutôt que sur l'administration LDAP bas niveau.

## Ce qu'il faut savoir configurer côté Keycloak (Phase 2)

- **Connection URL** : `ldap://lldap:3890` (nom du service Docker).
- **Bind DN** : le compte de service utilisé par Keycloak pour interroger LLDAP.
- **Users DN** : la base de recherche des utilisateurs.
- **Mappers d'attributs** : faire correspondre les attributs LDAP (`uid`, `mail`,
  `cn`...) aux attributs utilisateur Keycloak (`username`, `email`,
  `firstName`...).
- **Edit mode** : `READ_ONLY` (Keycloak ne modifie jamais LLDAP) vs
  `WRITABLE`/`UNSYNCED` (Keycloak peut modifier certains attributs côté annuaire).
