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

## Fase 5 — Verificación con curl (antes de activar en Decidim)

Ejecutar desde MAQUINA DECIDIM para confirmar que Nginx y los certificados están correctos antes de tocar el `.env`:

```bash
# Debe devolver respuesta válida de la API
curl -v \
  --cert /etc/ssl/galdakao/decidim-client.crt \
  --key  /etc/ssl/galdakao/decidim-client.key \
  --cacert /etc/ssl/galdakao/ca.crt \
  https://api.galdakao.eus/endpoint

# Debe fallar — sin certificado de cliente el servidor rechaza la conexión
curl -v \
  --cacert /etc/ssl/galdakao/ca.crt \
  https://api.galdakao.eus/endpoint
```

- [ ] Curl con cert → respuesta 200
- [ ] Curl sin cert → rechazo de conexión (error SSL handshake)

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

## Manual de mantenimiento — mTLS padrón municipal

> Fragmento para inclusión en el Manual de Mantenimiento de la plataforma Decidim Galdakao.
> Dirigido a mantenedores técnicos del sistema.

### Estructura de certificados

El mTLS entre Decidim y la API del padrón usa una CA propia (autofirmada). Los certificados se almacenan en `/etc/ssl/galdakao/` en cada servidor.

| Archivo | Servidor | Propósito |
|---|---|---|
| `ca.crt` | Ambos | Certificado de la CA raíz. Permite a cada parte verificar que el otro presenta un certificado firmado por la misma CA. |
| `ca.key` | Mantenedor | Clave privada de la CA. Necesaria únicamente para firmar nuevos certificados. No reside en ningún servidor. |
| `api-server.crt` / `api-server.key` | MAQUINA API | Identidad del servidor API ante Decidim. |
| `decidim-client.crt` / `decidim-client.key` | MAQUINA DECIDIM | Identidad de Decidim ante la API. |

### Renovación de certificados (expiración)

Los certificados tienen validez de 3650 días (≈10 años). Para renovarlos:

1. En la máquina del mantenedor, regenerar todos los certificados desde cero siguiendo la Fase 2 de esta hoja de ruta.
2. Distribuir con `rsync` siguiendo la Fase 3.
3. Recargar Nginx en MAQUINA API (`nginx -s reload`).
4. Reiniciar Decidim en MAQUINA DECIDIM.
5. Verificar con `curl` (Fase 5) antes de confirmar que todo está operativo.

No es necesario modificar código ni variables de entorno — las rutas a los archivos no cambian.

### Añadir un nuevo cliente a mTLS (sin afectar a Decidim)

Si en el futuro un nuevo servicio necesita conectarse a la API con mTLS:

1. Con la `ca.key` en la máquina del mantenedor, generar un nuevo certificado de cliente:

```bash
openssl genrsa -out nuevo-cliente.key 4096
openssl req -new -key nuevo-cliente.key -out nuevo-cliente.csr -subj "/CN=nuevo-cliente.galdakao.eus"
openssl x509 -req -days 3650 -in nuevo-cliente.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out nuevo-cliente.crt
```

2. Distribuir `nuevo-cliente.crt` y `nuevo-cliente.key` al nuevo servidor.
3. No es necesario tocar Nginx ni los certificados existentes — la CA ya está configurada como autoridad de confianza.

Si la `ca.key` no está disponible (perdida o expirada), regenerar todos los certificados desde cero siguiendo el proceso completo de esta hoja de ruta.

### Activar / desactivar mTLS en Decidim

El switch está en el `.env` de MAQUINA DECIDIM:

```bash
# Activar
GALDAKAO_CENSUS_TLS=true

# Desactivar (vuelve a conexión sin TLS, útil para diagnóstico)
GALDAKAO_CENSUS_TLS=false
```

Reiniciar Decidim tras cualquier cambio en `.env`.

### Diagnóstico de problemas de conexión

Si la autorización del padrón falla, verificar en este orden:

```bash
# 1. Comprobar que los certificados no han expirado
openssl x509 -in /etc/ssl/galdakao/decidim-client.crt -noout -dates
openssl x509 -in /etc/ssl/galdakao/api-server.crt -noout -dates

# 2. Verificar que los certificados están firmados por la misma CA
openssl verify -CAfile /etc/ssl/galdakao/ca.crt /etc/ssl/galdakao/decidim-client.crt
openssl verify -CAfile /etc/ssl/galdakao/ca.crt /etc/ssl/galdakao/api-server.crt

# 3. Probar la conexión mTLS directamente desde MAQUINA DECIDIM
curl -v \
  --cert /etc/ssl/galdakao/decidim-client.crt \
  --key  /etc/ssl/galdakao/decidim-client.key \
  --cacert /etc/ssl/galdakao/ca.crt \
  https://api.galdakao.eus/endpoint

# 4. Revisar logs de Nginx en MAQUINA API
tail -f /var/log/nginx/error.log
```

Si el `curl` funciona pero Decidim no, el problema está en las variables de entorno o en los permisos de los archivos (deben ser 600 y legibles por el usuario que ejecuta Decidim).