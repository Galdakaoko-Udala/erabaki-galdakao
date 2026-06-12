# Hoja de ruta — mTLS entre Decidim y API del padrón

## Arquitectura objetivo

```
Decidim (cliente mTLS)  ←——mTLS——→  Nginx (termina TLS)  →  Gunicorn (localhost)
```

---

## Principio de compatibilidad

El código de Decidim incluye un `IF` que permite operar **sin TLS** cuando las variables de entorno no están definidas o `GALDAKAO_CENSUS_TLS=false`. Esto garantiza que:

- En desarrollo (`development`) la conexión funciona como hasta ahora, sin cambios.
- Si la API no tiene TLS activo aún, Decidim sigue funcionando.
- La activación de mTLS es un switch en `.env`, sin tocar código.

---

## Fase 0 — Verificación del estado actual (sin TLS)

Antes de tocar nada, confirmar que la conexión actual funciona correctamente en todos los entornos.

- [x] Decidim conecta con la API sin TLS en desarrollo
- [x] Decidim conecta con la API sin TLS en producción
- [x] Las variables `GALDAKAO_CENSUS_TLS*` **no están definidas** en `.env` (punto de partida limpio)

---

## Fase 1 — Modificación de `galdakao_webservice.rb` (Decidim)

Añadir el método `faraday_client` con soporte mTLS condicional. La conexión sin TLS queda intacta cuando las variables no están definidas o `GALDAKAO_CENSUS_TLS=false`.

```ruby
def faraday_client
  tls_enabled = ENV["GALDAKAO_CENSUS_TLS"].to_s.downcase == "true"
  ca_cert     = ENV["GALDAKAO_CENSUS_TLS_CERT"].to_s.strip
  client_cert = ENV["GALDAKAO_CENSUS_TLS_CLIENT_CERT"].to_s.strip
  client_key  = ENV["GALDAKAO_CENSUS_TLS_CLIENT_KEY"].to_s.strip

  return Faraday.new unless tls_enabled

  Faraday.new do |f|
    f.ssl[:verify]      = true
    f.ssl[:ca_file]     = ca_cert      if ca_cert.present?
    f.ssl[:client_cert] = OpenSSL::X509::Certificate.new(File.read(client_cert)) if client_cert.present?
    f.ssl[:client_key]  = OpenSSL::PKey::RSA.new(File.read(client_key))          if client_key.present?
  end
end
```

Sustituir el `Faraday.post(census_url)` actual por:

```ruby
raw_response = faraday_client.post(census_url) do |request|
  request.headers["Content-Type"] = "text/xml; charset=UTF-8"
  request.body = request_body
end
```

Variables de entorno en `.env` — dejar vacías o sin definir para modo sin TLS:

```bash
GALDAKAO_CENSUS_TLS=false         # cambiar a true para activar mTLS
GALDAKAO_CENSUS_TLS_CERT=         # ruta a ca.crt
GALDAKAO_CENSUS_TLS_CLIENT_CERT=  # ruta a decidim-client.crt
GALDAKAO_CENSUS_TLS_CLIENT_KEY=   # ruta a decidim-client.key
```

- [x] Código modificado y desplegado
- [x] Verificar que con `GALDAKAO_CENSUS_TLS=false` la conexión sigue funcionando igual que antes
- [x] Commitear

---

## Fase 2 — Generación de certificados

Ejecutar en la máquina del mantenedor. Los archivos se distribuyen a los servidores mediante `rsync` en la Fase 3.

```bash
# CA raíz
openssl genrsa -out ca.key 4096
openssl req -new -x509 -days 3650 -key ca.key -out ca.crt -subj "/CN=GaldakaoCensusCA"

# Certificado del servidor API (para Nginx)
openssl genrsa -out api-server.key 4096
openssl req -new -key api-server.key -out api-server.csr -subj "/CN=api.galdakao.eus"
openssl x509 -req -days 3650 -in api-server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out api-server.crt

# Certificado del cliente Decidim
openssl genrsa -out decidim-client.key 4096
openssl req -new -key decidim-client.key -out decidim-client.csr -subj "/CN=decidim.galdakao.eus"
openssl x509 -req -days 3650 -in decidim-client.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out decidim-client.crt
```

**Distribución de archivos:**

| Archivo | Destino |
|---|---|
| `ca.crt` | Ambos servidores |
| `ca.key` | Solo en la máquina del mantenedor — necesaria para firmar nuevos certificados de cliente durante la vigencia de la CA (p.ej. añadir un nuevo servicio a mTLS sin regenerar todo) |
| `api-server.crt` + `api-server.key` | Servidor API — Nginx |
| `decidim-client.crt` + `decidim-client.key` | Servidor Decidim |

- [x] Certificados generados
- [ ] `ca.key` custodiada en la máquina del mantenedor

---

## Fase 3 — Distribución de certificados con rsync

Crear el directorio destino en ambos servidores antes del rsync:

```bash
# En MAQUINA API
ssh <MAQUINA_API> "mkdir -p /etc/ssl/galdakao"

# En MAQUINA DECIDIM
ssh <MAQUINA_DECIDIM> "mkdir -p /etc/ssl/galdakao"
```

Enviar los certificados correspondientes a cada servidor:

```bash
# Hacia MAQUINA API — CA, certificado y clave del servidor
rsync -av --chmod=600 \
  ca.crt \
  api-server.crt \
  api-server.key \
  <MAQUINA_API>:/etc/ssl/galdakao/

# Hacia MAQUINA DECIDIM — CA, certificado y clave del cliente
rsync -av --chmod=600 \
  ca.crt \
  decidim-client.crt \
  decidim-client.key \
  <MAQUINA_DECIDIM>:/etc/ssl/galdakao/
```

**⚠️ Ajuste de permisos en MAQUINA DECIDIM tras el rsync**

El rsync deja los archivos como `root:root`. El proceso Ruby dentro del contenedor Decidim corre como `uid=1000 (app)`, por lo que hay que ceder la propiedad:

```bash
# En MAQUINA DECIDIM — ejecutar tras el rsync
chown 1000:1000 /etc/ssl/galdakao/ca.crt \
                /etc/ssl/galdakao/decidim-client.crt \
                /etc/ssl/galdakao/decidim-client.key
chmod 640 /etc/ssl/galdakao/ca.crt \
          /etc/ssl/galdakao/decidim-client.crt \
          /etc/ssl/galdakao/decidim-client.key
```

Para verificar:
```bash
ls -la /etc/ssl/galdakao/
# Esperado: -rw-r----- 1 ubuntu ubuntu (uid 1000 en el host = usuario 'app' en el contenedor)
```

- [x] Certificados en `/etc/ssl/galdakao/` en MAQUINA API
- [x] Certificados en `/etc/ssl/galdakao/` en MAQUINA DECIDIM
- [x] Propietario `1000:1000` y permisos `640` en MAQUINA DECIDIM

---

## Fase 4 — Configuración de Docker Compose (Decidim)

El contenedor `app` necesita resolver el hostname `api.galdakao.eus` (CN del certificado del servidor) hacia la IP interna de MAQUINA API. Sin esto, Ruby valida que el hostname de la URL coincida con el CN del certificado y falla con `hostname does not match the server certificate`.

**`docker-compose.yml` — añadir `extra_hosts` al servicio `app`:**

```yaml
services:
  app:
    extra_hosts:
      - "api.galdakao.eus:<IP_MAQUINA_API>"
```

**`.env` de MAQUINA DECIDIM — usar el hostname del CN, no la IP:**

```bash
CENSUS_URL=https://api.galdakao.eus/soap
```

Verificar que resuelve correctamente dentro del contenedor:

```bash
docker compose exec app getent hosts api.galdakao.eus
# Esperado: <IP_MAQUINA_API>   api.galdakao.eus
```

- [x] `extra_hosts` añadido en `docker-compose.yml`
- [x] `CENSUS_URL` actualizada con el hostname en `.env`
- [x] Resolución verificada dentro del contenedor

---

## Fase 5 — Configuración Nginx (lado API)

Gunicorn no cambia — sigue escuchando en `127.0.0.1:8000` sin tocar TLS.

```nginx
server {
    listen 443 ssl;
    server_name api.galdakao.eus;

    ssl_certificate     /etc/ssl/galdakao/api-server.crt;
    ssl_certificate_key /etc/ssl/galdakao/api-server.key;

    # mTLS — verificar certificado del cliente
    ssl_client_certificate /etc/ssl/galdakao/ca.crt;
    ssl_verify_client on;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-SSL-Client-CN $ssl_client_s_dn_cn;
        proxy_set_header X-SSL-Client-Verify $ssl_client_verify;
    }
}

server {
    listen 80;
    server_name api.galdakao.eus;
    return 301 https://$host$request_uri;
}
```

- [x] Nginx configurado
- [x] `nginx -t` sin errores
- [x] Nginx recargado (`nginx -s reload`)

---

## Fase 6 — Verificación de la conexión mTLS

La verificación se realiza mediante una sincronización real desde el panel de administración de Decidim, revisando los logs de ambos servidores:

```bash
# En MAQUINA API — confirmar que Nginx acepta el handshake y el certificado cliente
tail -f /var/log/nginx/galdakao_api_access.log
tail -f /var/log/nginx/error.log

# En MAQUINA DECIDIM — confirmar que Faraday usa TLS y no hay errores de certificado
docker compose logs --tail=50 app | grep "Galdakao-Census"
```

Qué buscar en los logs tras intentar una sincronización:

- `[Galdakao-Census] TLS: activo` → el IF de Decidim está leyendo las variables correctamente
- `[Galdakao-Census] [ListadoCalles] SOAP status: 200` → conexión mTLS establecida y respuesta recibida
- Nginx access log muestra el CN del certificado cliente (`decidim.galdakao.eus`) y status 200
- Ausencia de errores `hostname does not match`, `Permission denied` o `EACCES`

- [x] Log de Decidim confirma TLS activo y SOAP status 200
- [x] Sincronización completada correctamente desde el panel de administración

---

## Fase 7 — Activación en Decidim

Una vez verificado, activar en `.env` de producción de MAQUINA DECIDIM y reiniciar:

```bash
GALDAKAO_CENSUS_TLS=true
GALDAKAO_CENSUS_TLS_CERT=/etc/ssl/galdakao/ca.crt
GALDAKAO_CENSUS_TLS_CLIENT_CERT=/etc/ssl/galdakao/decidim-client.crt
GALDAKAO_CENSUS_TLS_CLIENT_KEY=/etc/ssl/galdakao/decidim-client.key
```

- [x] Variables activadas en `.env`
- [x] Decidim reiniciado
- [x] Sincronización con padrón funciona correctamente con mTLS activo

---

## Fase 8 — Whitelist de IPs en Nginx (defensa en profundidad)

Capa adicional sobre mTLS. Solo la IP de MAQUINA DECIDIM puede llamar a la API, independientemente de que presente o no certificado válido:

```nginx
location / {
    allow <IP_MAQUINA_DECIDIM>;
    deny all;
    proxy_pass http://127.0.0.1:8000;
}
```

- [ ] IP de MAQUINA DECIDIM identificada y añadida
- [ ] `nginx -t` sin errores y Nginx recargado
- [ ] Verificar que desde otra IP la conexión es rechazada (403)