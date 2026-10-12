# pruebaApache

Mini-framework en PHP puro, sin dependencias, montado sobre Apache en Docker. El objetivo del
proyecto no son las páginas que sirve, sino la fontanería que las sirve: front controller único,
enrutado por tabla y separación controlador / vista, siguiendo las convenciones de Laravel pero
escrito a mano.

## Stack

- PHP 8.2 + Apache (`php:8.2-apache`), con las extensiones `pdo`, `pdo_mysql` y `gd`
- MySQL 8.0
- phpMyAdmin
- Tailwind CSS vía CDN de navegador (solo desarrollo)

## Arrancar el proyecto

```bash
# La primera vez (construye la imagen):
docker compose up -d --build

# Después:
docker compose up -d
```

| Servicio   | URL                   | Credenciales  |
|------------|-----------------------|---------------|
| Web        | http://localhost:8080 | —             |
| phpMyAdmin | http://localhost:8081 | `root` / `root` |

La base de datos se llama `links` y se crea sola al inicializar el volumen. MySQL no publica el
puerto 3306 al host: `web` y phpMyAdmin la alcanzan por la red interna de Compose. Si necesitas
conectar un cliente externo (DBeaver, TablePlus), añade `ports: ["3306:3306"]` al servicio `mysql`.

Si el 8080 ya está ocupado en tu máquina, cambia el mapeo del servicio `web` en
`docker-compose.yml` (por ejemplo `"8000:80"`).

Para parar la pila:

```bash
docker compose down      # conserva los datos
docker compose down -v   # borra también el volumen de MySQL
```

> Ojo: MySQL solo aplica `MYSQL_ROOT_PASSWORD` y `MYSQL_DATABASE` cuando inicializa un volumen
> vacío. Si cambias esas variables sobre un volumen ya existente, se ignoran en silencio y la
> conexión falla con *access denied*. En ese caso hace falta `down -v`.

## Estructura

```
src/
├── public/
│   └── index.php              # Front controller: único punto de entrada
├── routes/
│   └── web.php                # Tabla de rutas: URI → controlador
├── app/
│   └── Controllers/           # Un archivo por ruta; prepara datos y carga su vista
└── resources/
    ├── *.template.php         # Vistas
    └── partials/              # header, navbar, footer
```

El `DocumentRoot` de Apache apunta a `/var/www/html/public`, así que nada fuera de `public/` es
accesible desde el navegador. La reescritura que manda todo a `index.php` está declarada en el
`Dockerfile` como configuración de Apache (`conf-available/public-rewrite.conf`), no en un
`.htaccess` — así no depende del volumen montado.

En desarrollo, `./src` se monta como volumen: los cambios en PHP se ven al recargar, sin
reconstruir la imagen.

### Rutas actuales

| URI      | Controlador                     | Vista                  |
|----------|---------------------------------|------------------------|
| `/`      | `app/Controllers/home.php`      | `home.template.php`    |
| `/post`  | `app/Controllers/post.php`      | `post.template.php`    |
| `/blog`  | `app/Controllers/blog.php`      | `blog.template.php`    |
| `/about` | `app/Controllers/about.php`     | `about.template.php`   |
| `/links` | `app/Controllers/links.php`     | `links.template.php`   |

## Pendiente

Ordenado por lo que bloquea antes, no por importancia abstracta.

### Para conectar la base de datos

- [ ] **Capa de datos.** Las variables `DB_HOST`, `DB_PORT`, `DB_DATABASE`, `DB_USERNAME` y
      `DB_PASSWORD` llegan al contenedor pero ningún PHP las lee. Falta un único punto de
      conexión (`app/Core/Database.php`) con `PDO::ERRMODE_EXCEPTION` y `charset=utf8mb4`.
      No repartir `new PDO` por los controladores.
- [ ] **Esquema y semilla.** Nada en el repo crea las tablas, así que el proyecto no es
      reproducible: quien clone y arranque se queda sin ellas. Un `database/schema.sql` montado
      en `/docker-entrypoint-initdb.d` lo resuelve sin herramientas extra.
- [ ] **Rutas con parámetros.** `routes/web.php` compara la URI exacta contra un array, así que
      `/post/5` o `/post/mi-articulo` son imposibles. Tampoco se distingue el método HTTP, lo que
      impide separar GET de POST en una misma URL cuando haya formularios. Es el techo
      arquitectónico más cercano y el único pendiente que obliga a reescribir código ya hecho si
      se deja para después.

### Deuda estructural

- [ ] **Composer y autoload PSR-4.** Los controladores son `require` que se comunican por
      variables globales (`$title`). Aguanta cinco páginas estáticas, no clases de modelo.
- [ ] **Escape de salida.** Hoy todo el texto está escrito a mano, pero en cuanto el contenido
      venga de MySQL, cualquier `<?= $post['titulo'] ?>` es un XSS. Un helper `e()` sobre
      `htmlspecialchars` cuesta nada ahora y obliga a revisar cada plantilla después.
- [ ] **Layout en las vistas.** Cada `*.template.php` repite a mano el `require` del header y del
      footer. Un helper `view($nombre, $datos)` elimina la duplicación y da un sitio donde pasar
      datos explícitamente en vez de por variable global.
- [ ] **404 de verdad.** `index.php` termina con `exit('404 Not Found')`, que devuelve **HTTP
      200**. Falta `http_response_code(404)` y una vista propia.
- [ ] **Gestión de errores.** No hay distinción dev/prod. Una excepción de PDO sin capturar
      imprime la cadena de conexión, credenciales incluidas, en el navegador.
- [ ] **Navbar.** `partials/navbar.php` repite el mismo bloque cinco veces. Un array
      `['/' => 'Inicio', ...]` y un `foreach` lo dejan en pocas líneas, y añadir una sección pasa
      a ser una línea.
- [ ] **`$title` inconsistente.** `home.php` no lo define y cae al valor por defecto; los otros
      cuatro controladores sí lo definen.
- [ ] **CSS.** `partials/header.php` usa `container mx-3`, que se pelea consigo mismo:
      `container mx-auto px-4` es lo que se busca.

### Más adelante

Innecesario al tamaño actual: build real de Tailwind (el CDN basta hasta publicar), tests, CI.
