#!/usr/bin/env bash
#
# Démo OpenFGA : crée un store, y écrit le modèle document-model.fga, écrit
# des relations (tuples) de démonstration, puis vérifie des permissions.
#
# Prérequis : Phase 4 démarrée (docker compose up -d), CLI "fga" installé.
#   Installation : https://github.com/openfga/cli#installation
#   (brew install openfga/tap/fga, ou binaire précompilé, ou `go install`)
#
# Usage : ./openfga-demo.sh

set -euo pipefail

FGA_API_URL="${FGA_API_URL:-http://localhost:8081}"
MODEL_FILE="$(dirname "$0")/../model/document-model.fga"

if ! command -v fga >/dev/null 2>&1; then
  echo "Le CLI 'fga' n'est pas installé -- voir le README de cette phase." >&2
  exit 1
fi

echo "=== 1. Création du store + écriture du modèle ==="
RESPONSE="$(fga store create --api-url "$FGA_API_URL" --name lab-iam-documents --model "$MODEL_FILE")"
echo "$RESPONSE" | jq .

STORE_ID="$(echo "$RESPONSE" | jq -r '.store.id')"
MODEL_ID="$(echo "$RESPONSE" | jq -r '.model.authorization_model_id')"

echo
echo "Store ID : $STORE_ID"
echo "Model ID : $MODEL_ID"

echo
echo "=== 2. Écriture des relations (tuples) de démonstration ==="
echo "alice = owner de folder:projet-x"
fga tuple write --api-url "$FGA_API_URL" --store-id "$STORE_ID" --model-id "$MODEL_ID" \
  user:alice owner folder:projet-x

echo "bob = viewer de folder:projet-x"
fga tuple write --api-url "$FGA_API_URL" --store-id "$STORE_ID" --model-id "$MODEL_ID" \
  user:bob viewer folder:projet-x

echo "document:roadmap a pour parent folder:projet-x"
fga tuple write --api-url "$FGA_API_URL" --store-id "$STORE_ID" --model-id "$MODEL_ID" \
  folder:projet-x parent document:roadmap

check() {
  local user="$1" relation="$2" object="$3"
  local result
  result="$(fga query check --api-url "$FGA_API_URL" --store-id "$STORE_ID" --model-id "$MODEL_ID" \
    "$user" "$relation" "$object" | jq -r '.allowed')"
  printf '  %-12s %-8s %-22s -> allowed=%s\n' "$user" "$relation" "$object" "$result"
}

echo
echo "=== 3. Vérifications (Check) ==="
echo "Attendu : true -- alice est owner du dossier parent, donc éditrice héritée du document"
check user:alice editor document:roadmap

echo "Attendu : true -- bob est viewer du dossier parent, hérité par le document"
check user:bob viewer document:roadmap

echo "Attendu : false -- être viewer n'accorde pas les droits d'édition"
check user:bob editor document:roadmap

echo "Attendu : false -- eve n'a aucune relation avec ce document ou son dossier parent"
check user:eve viewer document:roadmap

echo
echo "C'est exactement l'exercice à refaire toi-même avec de nouveaux tuples :"
echo "  fga tuple write --api-url \"$FGA_API_URL\" --store-id \"$STORE_ID\" --model-id \"$MODEL_ID\" <user> <relation> <object>"
echo "  fga query check --api-url \"$FGA_API_URL\" --store-id \"$STORE_ID\" --model-id \"$MODEL_ID\" <user> <relation> <object>"
