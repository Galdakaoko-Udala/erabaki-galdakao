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

# 3. Intentar una autorización desde el formulario con un usuario de prueba
#    y revisar los logs en tiempo real

# En MAQUINA DECIDIM
tail -f /ruta/logs/production.log | grep "Galdakao-Census"

# En MAQUINA API
tail -f /var/log/nginx/error.log
tail -f /var/log/nginx/galdakao_api_access.log

# 4. Revisar logs de Nginx en MAQUINA API
tail -f /var/log/nginx/error.log
```

Si el `curl` funciona pero Decidim no, el problema está en las variables de entorno o en los permisos de los archivos (deben ser 600 y legibles por el usuario que ejecuta Decidim).