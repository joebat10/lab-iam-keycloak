#!/usr/bin/env bash
#
# Récupère les fichiers officiels de déploiement Docker Compose de Zitadel.
# On utilise volontairement les fichiers officiels (et non une réécriture
# maison) pour ce produit : son architecture event-sourcée a des exigences
# de configuration précises que seule la source officielle garantit à jour.
#
# Source : https://github.com/zitadel/zitadel (dossier deploy/compose)

set -euo pipefail

cd "$(dirname "$0")"

curl -LO https://raw.githubusercontent.com/zitadel/zitadel/main/deploy/compose/docker-compose.yml
curl -LO https://raw.githubusercontent.com/zitadel/zitadel/main/deploy/compose/.env.example
cp .env.example .env

echo
echo "Fichiers récupérés. Étapes suivantes :"
echo "  1. Édite ./.env si besoin (mots de passe, ports)."
echo "  2. docker compose up -d --wait"
echo "  3. Console : https://localhost:8443 (ou le port défini dans .env)"
