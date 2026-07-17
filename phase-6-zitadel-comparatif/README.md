# Phase 6 — Regard d'architecte : Keycloak vs Zitadel

Cette phase n'a pas de "notion" nouvelle à lire au préalable — c'est un
exercice de comparaison, volontairement placé en dernier.

## Démarrer Zitadel (fichiers officiels)

```bash
cd phase-6-zitadel-comparatif
./fetch-official-compose.sh
docker compose up -d --wait
```

Console : voir la sortie de la commande (`https://localhost:8443` par défaut
selon le `.env.example` officiel). Identifiants initiaux dans les logs du
premier démarrage (`docker compose logs`).

> On utilise ici les fichiers officiels de Zitadel plutôt qu'une réécriture
> maison : son architecture event-sourcée impose des réglages précis
> (versions, ports, certificats auto-signés générés au premier démarrage)
> qu'il vaut mieux laisser à la source qui les maintient à jour.

## Ce que tu dois observer, pas juste lire

1. **Multi-tenance** : dans Zitadel, crée une Organisation, puis un Projet à
   l'intérieur. Compare mentalement avec la structure Realm → Client de
   Keycloak (Phase 1). Est-ce vraiment équivalent ? (Indice : dans Zitadel,
   une instance peut héberger un nombre très large d'organisations
   indépendantes avec isolation stricte ; un realm Keycloak est plus proche
   d'un "tout en un" par domaine de confiance — les implications en termes de
   scalabilité et d'isolation ne sont pas les mêmes.)
2. **Modèle de données** : Zitadel stocke chaque changement comme un
   événement immuable (event sourcing) — d'où un historique d'audit natif
   et complet. Keycloak stocke un état courant en base relationnelle
   classique, avec un système d'audit plus classique en complément.
3. **API-first** : essaie de créer un utilisateur Zitadel uniquement via son
   API REST/gRPC (pas la console), puis compare l'effort avec l'Admin REST
   API de Keycloak.

## Rédige ton comparatif

Une fois les points ci-dessus manipulés (pas juste lus), remplis
`COMPARATIF.md` dans ce dossier avec ton propre avis argumenté — c'est ce
document, pas Zitadel lui-même, qui est le vrai livrable de cette phase pour
un profil architecte.

## Definition of done de cette phase

- [ ] Zitadel tourne, tu as créé une organisation et un projet.
- [ ] Tu as créé un utilisateur via l'API plutôt que la console au moins une
      fois.
- [ ] `COMPARATIF.md` est rempli avec ton propre avis, pas une copie de
      tableau marketing.

## Et après ?

Retourne à `../ROADMAP.md`, section "Après le plan" — c'est là que
continuer une fois les 6 phases terminées.
