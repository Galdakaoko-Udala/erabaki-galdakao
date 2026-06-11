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

- [ ] Decidim conecta con la API sin TLS en desarrollo
- [ ] Decidim conecta con la API sin TLS en producción
- [ ] Las variables `GALDAKAO_CENSUS_TLS*` **no están definidas** en `.env` (punto de partida limpio)

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

- [ ] Código modificado y desplegado
- [ ] Verificar que con `GALDAKAO_CENSUS_TLS=false` la conexión sigue funcionando igual que antes
- [ ] Commitear

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

- [ ] Certificados generados
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

- [ ] Certificados en `/etc/ssl/galdakao/` en MAQUINA API
- [ ] Certificados en `/etc/ssl/galdakao/` en MAQUINA DECIDIM
- [ ] Permisos 600 verificados en ambos servidores

---

## Fase 4 — Configuración Nginx (lado API)

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

- [ ] Nginx configurado
- [ ] `nginx -t` sin errores
- [ ] Nginx recargado (`nginx -s reload`)

---

## Fase 5 — Verificación de la conexión mTLS
La verificación se realiza mediante una autorización real desde el formulario de Decidim con un usuario de prueba, revisando los logs de ambos servidores:

```bash
# En MAQUINA API — confirmar que Nginx acepta el handshake y el certificado cliente
tail -f /var/log/nginx/galdakao_api_access.log
tail -f /var/log/nginx/error.log

# En MAQUINA DECIDIM — confirmar que Faraday usa TLS y no hay errores de certificado
tail -f /ruta/logs/production.log | grep "Galdakao-Census"
Qué buscar en los logs tras intentar una autorización:
```

[Galdakao-Census] TLS: activo → el IF de Decidim está leyendo las variables correctamente
Nginx access log muestra el CN del certificado cliente (decidim.galdakao.eus) y status 200
Ausencia de errores [Galdakao-Census] TLS activo pero ... no definido
- [ ] Log de Decidim confirma TLS activo
- [ ] Log de Nginx confirma certificado cliente aceptado y status 200
- [ ] Autorización completada correctamente desde el formulario


---

## Fase 6 — Activación en Decidim

Una vez verificado con curl, activar en `.env` de producción de MAQUINA DECIDIM y reiniciar:

```bash
GALDAKAO_CENSUS_TLS=true
GALDAKAO_CENSUS_TLS_CERT=/etc/ssl/galdakao/ca.crt
GALDAKAO_CENSUS_TLS_CLIENT_CERT=/etc/ssl/galdakao/decidim-client.crt
GALDAKAO_CENSUS_TLS_CLIENT_KEY=/etc/ssl/galdakao/decidim-client.key
```

- [ ] Variables activadas en `.env`
- [ ] Decidim reiniciado
- [ ] Autorización con padrón funciona correctamente con mTLS activo

---

## Fase 7 — Whitelist de IPs en Nginx (defensa en profundidad)

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

---