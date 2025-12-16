#!/bin/bash

set -euxo pipefail

# Dossier où chercher les configs (priorité à /conf monté, fallback /etc/wireguard)
WG_CONF_DIR="/conf"
if [[ ! -d "$WG_CONF_DIR" ]]; then
    WG_CONF_DIR="/etc/wireguard"
fi

# Démarre toutes les interfaces clientes WireGuard trouvées
for conf in "$WG_CONF_DIR"/wg*-client.conf "$WG_CONF_DIR"/client-*.conf "$WG_CONF_DIR"/vpn-*.conf; do
    [[ -e "$conf" ]] || continue # Passe si aucun fichier ne matche
    iface="$(basename "$conf" .conf)"
    # Ne démarre que si l'interface n'existe pas déjà
    if ! ip link show "$iface" &>/dev/null; then
        echo "➡️  Lancement interface WireGuard cliente : $iface"
        wg-quick up "$conf"
        DYNAMIC_WG_INTERFACES+=("$iface")
    else
        echo "✔️  Interface $iface déjà active"
    fi
done

# Fonction de nettoyage à appeler à la sortie du conteneur
wg_cleanup() {
    echo "⏬ Arrêt interfaces WireGuard clientes (auto-discover)..."
    for iface in "${DYNAMIC_WG_INTERFACES[@]}"; do
        if ip link show "$iface" &>/dev/null; then
            echo "⏹️  Suppression interface $iface"
            wg-quick down "$iface" || true
        fi
    done
}


trap wg_cleanup EXIT

sleep infinity