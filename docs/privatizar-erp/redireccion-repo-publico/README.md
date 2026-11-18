# Repositorio público mínimo de redirección (SIN datos del negocio)

Sirve solo para que `https://lana-rosa.github.io/ERP/` siga llevando a `https://larova.lanarosacrochet.com/erp/` cuando el repositorio `lana-rosa/ERP` pase a privado.

- Nombre del repositorio nuevo, **exactamente**: `lana-rosa.github.io` (sitio de la organización), **público**.
- Contenido: estos archivos (`404.html`, `ERP/index.html`, `ERP/sw.js`). No lleva ningún dato del negocio ni llaves.
- Activar GitHub Pages: Settings → Pages → Source: *Deploy from a branch* → `main` / `(root)`.
- Crear este repositorio y activar Pages **no cambia nada hoy**: mientras `lana-rosa/ERP` siga público con Pages, GitHub sigue sirviendo `/ERP/` desde ese repositorio. La redirección solo empieza a funcionar cuando el ERP pasa a privado.

## Cómo comprobarlo ANTES de hacer privado el ERP
- `prueba-redireccion/index.html` es una copia de `ERP/index.html` en una carpeta que no choca con nada. Con Pages activado, `https://lana-rosa.github.io/prueba-redireccion/` debe llevar a `https://larova.lanarosacrochet.com/erp/`. Eso prueba que el repositorio y Pages funcionan.
- `https://lana-rosa.github.io/ERP/` **todavía** abre el ERP viejo (lo sirve el repositorio `ERP`); pasa a redirigir solo cuando `ERP` pasa a privado.
- Después de verificar todo, se puede borrar la carpeta `prueba-redireccion/`.
