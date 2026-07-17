# Phase 0 — Prérequis et environnement

## Objectif

Avoir un environnement reproductible avant de toucher à Keycloak.

## Checklist d'installation

```bash
# Docker + Compose v2 (Linux Debian/Ubuntu)
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER   # puis se reconnecter
docker compose version          # doit afficher v2.x
```

Sur Windows : utilise WSL2 + Docker Desktop (option "WSL2 backend" activée).
Sur macOS : Docker Desktop suffit.

## Outils en ligne de commande utiles pour tout le lab

```bash
sudo apt install -y curl jq openssl
```

- `curl` : appeler les API REST de Keycloak/OpenFGA/midPoint directement.
- `jq` : lire/filtrer des réponses JSON lisiblement dans le terminal.
- `openssl` : générer les valeurs aléatoires PKCE (`code_verifier`) en Phase 3.

## Un principe à retenir avant de démarrer

Keycloak (comme beaucoup d'outils Java/Quarkus) a deux modes très différents :

- `start-dev` : rapide, base H2 en mémoire, HTTP non sécurisé toléré — **jamais
  en production**, mais parfait pour ce lab.
- `start --optimized` : mode production, nécessite TLS, une vraie base de
  données, un build préalable de l'image.

Toutes les phases de ce lab utilisent volontairement le mode dev pour rester
simples et rapides à itérer. `phase-1-keycloak-core/README.md` revient sur ce
point avec un avertissement explicite à ne pas ignorer si tu comptes un jour
exposer ce lab au-delà de ta machine.

## Fait ?

Une fois `docker compose version` fonctionnel, passe à
`../phase-1-keycloak-core/README.md`.
