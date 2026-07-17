#!/usr/bin/env bash
#
# Rejoue à la main un flux OAuth2/OIDC Authorization Code + PKCE contre
# Keycloak, avec curl uniquement -- pour VOIR chaque appel HTTP, pas pour
# servir de base à une application réelle (le paste manuel du code
# d'autorisation n'a de sens que dans un lab).
#
# Prérequis : Phase 1 démarrée, realm "lab-iam", client public "demo-spa"
# avec redirect URI "http://localhost:3000/*", utilisateur "alice".
# Dépendances : curl, jq, openssl.
#
# Usage : ./oidc-flow-curl-demo.sh

set -euo pipefail

KC_BASE="${KC_BASE:-http://localhost:8080}"
REALM="${REALM:-lab-iam}"
CLIENT_ID="${CLIENT_ID:-demo-spa}"
REDIRECT_URI="${REDIRECT_URI:-http://localhost:3000/callback}"

# Client confidentiel de la Phase 1, utilisé uniquement pour la démo
# d'introspection (RFC 7662 exige un client authentifié).
INTROSPECTION_CLIENT_ID="${INTROSPECTION_CLIENT_ID:-demo-backend}"
INTROSPECTION_CLIENT_SECRET="${INTROSPECTION_CLIENT_SECRET:-}"

TOKEN_ENDPOINT="${KC_BASE}/realms/${REALM}/protocol/openid-connect/token"
AUTH_ENDPOINT="${KC_BASE}/realms/${REALM}/protocol/openid-connect/auth"
INTROSPECT_ENDPOINT="${KC_BASE}/realms/${REALM}/protocol/openid-connect/token/introspect"
LOGOUT_ENDPOINT="${KC_BASE}/realms/${REALM}/protocol/openid-connect/logout"

b64url() {
  # base64url sans padding, lit stdin
  openssl base64 -A | tr '+/' '-_' | tr -d '='
}

decode_jwt() {
  # $1 = un JWT ; affiche son payload décodé en JSON via jq
  local payload
  payload="$(cut -d. -f2 <<<"$1")"
  local mod=$(( ${#payload} % 4 ))
  if [ "$mod" -eq 2 ]; then payload="${payload}=="; elif [ "$mod" -eq 3 ]; then payload="${payload}="; fi
  tr '_-' '/+' <<<"$payload" | base64 -d 2>/dev/null | jq .
}

echo "=== 1. Génération PKCE (RFC 7636) ==="
CODE_VERIFIER="$(openssl rand -base64 96 | tr -d '\n' | tr '+/' '-_' | tr -d '=')"
CODE_CHALLENGE="$(printf '%s' "$CODE_VERIFIER" | openssl dgst -sha256 -binary | b64url)"
STATE="$(openssl rand -hex 8)"

echo "code_verifier  : $CODE_VERIFIER"
echo "code_challenge : $CODE_CHALLENGE (= base64url(sha256(code_verifier)))"
echo "state          : $STATE"
echo

AUTH_URL="${AUTH_ENDPOINT}?client_id=${CLIENT_ID}&redirect_uri=${REDIRECT_URI}&response_type=code&scope=openid%20profile%20email&code_challenge=${CODE_CHALLENGE}&code_challenge_method=S256&state=${STATE}"

echo "=== 2. Ouvre cette URL dans ton navigateur et connecte-toi (ex. alice) ==="
echo "$AUTH_URL"
echo
echo "Après le login, le navigateur va être redirigé vers une URL du type"
echo "http://localhost:3000/callback?state=...&code=... (une erreur \"page introuvable\""
echo "est normale, rien n'écoute sur ce port ici -- copie l'URL depuis la barre d'adresse)."
echo

read -r -p "Colle ici l'URL complète de redirection : " REDIRECT_RESULT

CODE="$(grep -oE 'code=[^&]+' <<<"$REDIRECT_RESULT" | cut -d= -f2)"
RETURNED_STATE="$(grep -oE 'state=[^&]+' <<<"$REDIRECT_RESULT" | cut -d= -f2)"

if [ "$RETURNED_STATE" != "$STATE" ]; then
  echo "ERREUR : le state renvoyé ne correspond pas -- possible CSRF, on arrête ici." >&2
  exit 1
fi

echo
echo "=== 3. Échange du code contre les tokens (avec code_verifier) ==="
TOKEN_RESPONSE="$(curl -s -X POST "$TOKEN_ENDPOINT" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=authorization_code" \
  -d "client_id=${CLIENT_ID}" \
  -d "code=${CODE}" \
  -d "redirect_uri=${REDIRECT_URI}" \
  -d "code_verifier=${CODE_VERIFIER}")"

echo "$TOKEN_RESPONSE" | jq .

ACCESS_TOKEN="$(jq -r '.access_token' <<<"$TOKEN_RESPONSE")"
REFRESH_TOKEN="$(jq -r '.refresh_token' <<<"$TOKEN_RESPONSE")"
ID_TOKEN="$(jq -r '.id_token' <<<"$TOKEN_RESPONSE")"

echo
echo "=== 4. Claims de l'ID Token décodé ==="
decode_jwt "$ID_TOKEN"

echo
echo "=== 5. Refresh : nouvel access_token SANS ré-authentification ==="
REFRESH_RESPONSE="$(curl -s -X POST "$TOKEN_ENDPOINT" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=refresh_token" \
  -d "client_id=${CLIENT_ID}" \
  -d "refresh_token=${REFRESH_TOKEN}")"

echo "$REFRESH_RESPONSE" | jq .
NEW_REFRESH_TOKEN="$(jq -r '.refresh_token' <<<"$REFRESH_RESPONSE")"

if [ "$NEW_REFRESH_TOKEN" != "$REFRESH_TOKEN" ] && [ "$NEW_REFRESH_TOKEN" != "null" ]; then
  echo
  echo "--> Refresh Token Rotation observée : l'ancien refresh_token est"
  echo "    désormais invalide, un nouveau a été émis (compare les deux valeurs)."
fi

echo
if [ -n "$INTROSPECTION_CLIENT_SECRET" ]; then
  echo "=== 6. Introspection de l'access_token (RFC 7662, client confidentiel) ==="
  curl -s -X POST "$INTROSPECT_ENDPOINT" \
    -u "${INTROSPECTION_CLIENT_ID}:${INTROSPECTION_CLIENT_SECRET}" \
    -d "token=${ACCESS_TOKEN}" | jq .
else
  echo "=== 6. Introspection ignorée ==="
  echo "Exporte INTROSPECTION_CLIENT_SECRET (secret du client 'demo-backend',"
  echo "onglet Credentials, Phase 1) pour tester cette étape."
fi

echo
echo "=== 7. Révocation / logout (invalide le refresh_token côté serveur) ==="
curl -s -X POST "$LOGOUT_ENDPOINT" \
  -d "client_id=${CLIENT_ID}" \
  -d "refresh_token=${NEW_REFRESH_TOKEN}" -o /dev/null -w "HTTP %{http_code}\n"

echo
echo "Essaie de réutiliser ce refresh_token maintenant (grant_type=refresh_token" 
echo "avec la même valeur) : Keycloak doit répondre une erreur -- c'est la preuve"
echo "que la révocation a bien fonctionné."
