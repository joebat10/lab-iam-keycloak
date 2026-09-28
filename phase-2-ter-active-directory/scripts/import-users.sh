#!/usr/bin/env bash
set -uo pipefail

CSV="${1:-data/employes-poitiers.csv}"
CONTAINER="${CONTAINER:-samba-ad}"
PASSWORD="${DEFAULT_PASSWORD:-Norvalis-2026!}"
OU_USERS="OU=Utilisateurs,OU=Poitiers"
DOMAINE="norvalis.local"

if [ ! -f "$CSV" ]; then
  echo "Fichier introuvable : $CSV" >&2
  exit 1
fi

crees=0
ignores=0
echecs=0

while IFS=';' read -r login prenom nom service fonction groupe; do
  [ -z "$login" ] && continue

  if docker exec "$CONTAINER" samba-tool user show "$login" >/dev/null 2>&1 </dev/null; then
    echo "= $login existe deja, ignore"
    ignores=$((ignores + 1))
    continue
  fi

  mail="$(printf '%s.%s' "$prenom" "$nom" | tr '[:upper:]' '[:lower:]')@${DOMAINE}"

  if docker exec "$CONTAINER" samba-tool user create "$login" "$PASSWORD" \
       --userou="$OU_USERS" \
       --given-name="$prenom" --surname="$nom" \
       --mail-address="$mail" \
       --department="$service" --job-title="$fonction" \
       >/dev/null 2>&1 </dev/null; then
    docker exec "$CONTAINER" samba-tool group addmembers "$groupe" "$login" >/dev/null 2>&1 </dev/null
    echo "+ $login cree, groupe $groupe"
    crees=$((crees + 1))
  else
    echo "! ECHEC pour $login" >&2
    echecs=$((echecs + 1))
  fi
done < <(tail -n +2 "$CSV" | tr -d '\r')

echo
echo "Bilan : $crees crees, $ignores ignores, $echecs echecs"
