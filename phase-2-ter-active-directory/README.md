# Phase 2 ter — Active Directory (Samba4)

Contexte Norvalis : le site de Poitiers utilise un vrai Active Directory
(herite d'avant la centralisation IAM), contrairement au siege qui est passe
sur LLDAP. Objectif : federer ce second annuaire sur le meme Keycloak.

## Etape 1 -- Demarrer Samba4

cd ~/projets/lab-iam-keycloak/phase-2-ter-active-directory
cp .env.example .env
docker compose up -d
docker compose logs -f samba-ad

La premiere fois, Samba provisionne un domaine complet -- ca peut prendre
1 a 2 minutes. Attends une ligne qui indique que Samba a demarre, puis
Ctrl+C pour sortir des logs.

## Verifie

docker compose ps

Le conteneur samba-ad doit etre Up.

## Point de vigilance

Ce conteneur emule un vrai service Windows (DNS + Kerberos + LDAP), donc
plus susceptible de bugs sous WSL2 que nos autres services. Colle les logs
directement si ca bloque.
