#!/usr/bin/env bash
# Arma la carpeta "dist" para Cloudflare Pages (larova.lanarosacrochet.com):
#   /            -> portada LAROVA (larova.html)
#   /erp/        -> la app del ERP (index.html, sw.js, manifest, íconos)
# NO publica docs/, supabase/, scripts/ ni CLAUDE.md.
# La dirección vieja (GitHub Pages: lana-rosa.github.io/ERP/) sigue funcionando sin este script.
# Uso en Cloudflare Pages: Build command = bash scripts/build-larova.sh ; Output directory = dist
set -euo pipefail
cd "$(dirname "$0")/.."

rm -rf dist
mkdir -p dist/erp

# --- ERP en /erp/ ---
cp index.html sw.js manifest.json logo-animado.html apple-touch-icon.png icon-192.png icon-512.png icon-maskable-192.png icon-maskable-512.png dist/erp/

# --- Portada en la raíz ---
cp larova.html dist/index.html
cp apple-touch-icon.png icon-192.png dist/
cp -r iconos-larova dist/

# Ajustar los dos enlaces que cambian de lugar (falla si el texto ya no existe, para no publicar algo roto)
cambiar() { # archivo, texto viejo, texto nuevo
  grep -qF -- "$2" "$1" || { echo "ERROR: no encontré «$2» en $1" >&2; exit 1; }
  python3 - "$1" "$2" "$3" <<'PY'
import sys
p, a, b = sys.argv[1:4]
s = open(p, encoding='utf-8').read()
open(p, 'w', encoding='utf-8').write(s.replace(a, b))
PY
}
cambiar dist/index.html 'href="./index.html"' 'href="./erp/"'
cambiar dist/erp/index.html 'href="./larova.html"' 'href="../"'
# Gestión y CRM viven dentro de esta misma dirección (ver functions/ y proxy/)
cambiar dist/index.html 'href="https://lana-rosa.github.io/CRM/"' 'href="./CRM/"'
cambiar dist/index.html 'href="https://lana-rosa.github.io/SO/"' 'href="./gestion/"'

# --- Marketing y comunicación (pantalla aparte; usa la sesión del ERP, mismo dominio) ---
cp marketing.html dist/marketing.html
cambiar dist/marketing.html 'href="./larova.html#administracion"' 'href="./#administracion"'
cambiar dist/marketing.html 'href="./index.html"' 'href="./erp/"'

# El service worker nunca se guarda en caché del navegador por mucho tiempo
cat > dist/_headers <<'H'
/erp/sw.js
  Cache-Control: no-cache
/erp/manifest.json
  Cache-Control: no-cache
/*.png
  Cache-Control: no-cache
/erp/*.png
  Cache-Control: no-cache
H

echo "OK: dist/ listo ($(find dist -type f | wc -l) archivos)"
