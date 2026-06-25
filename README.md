# decidim-app

Free Open-Source participatory democracy, citizen participation and open government for cities and organizations

This is the open-source repository for decidim-galdakao, based on [Decidim](https://github.com/decidim/decidim).

[![Test](https://github.com/Galdakaoko-Udala/erabaki-galdakao/actions/workflows/test.yml/badge.svg)](https://github.com/Galdakaoko-Udala/erabaki-galdakao/actions/workflows/test.yml)

This is the instance for Erabaki Galdakao https://erabaki.galdakao.eus

## Server configuration

Docker & Docker Compose is needed, then clone this repository:

```
git clone https://github.com/Galdakaoko-Udala/erabaki-galdakao decidim_production
```

or update:
```
cd decidim_production
git pull
```

Ensure the `.env` file has these values defined:

```bash
DATABASE_URL=postgres://xxxxx:xxxxx@db/xxxxx
POSTGRES_USER=XXXXXX
POSTGRES_PASSWORD=XXXXXX
POSTGRES_DB=XXXXXX
SECRET_KEY_BASE=XXXXXX
MAPS_PROVIDER=here
MAPS_API_KEY=XXXXXX
EMAIL=XXXXXX
SMTP_USERNAME=XXXXXX
SMTP_PASSWORD=XXXXXX
SMTP_ADDRESS=XXXXXX
SMTP_DOMAIN=XXXXXX
SMTP_PORT=XXXXXX
DECIDIM_ENV=production
```

### SSL configuration

This application uses Traefik to handle the certificates, ensure that the following files are available:

- `certs/cert.crt`
- `certs/cert.key`

### mTLS configuration (census API)

The census authorization module connects to the municipal register API via mTLS. This is optional — when the variables below are not defined or `GALDAKAO_CENSUS_TLS=false`, the connection falls back to plain HTTP.

**Certificates**

Place the following files on the host with owner `1000:1000` and permissions `640`:

```
/etc/ssl/galdakao/ca.crt
/etc/ssl/galdakao/decidim-client.crt
/etc/ssl/galdakao/decidim-client.key
```

These files are mounted into the container as a volume (see `docker-compose.yml`).

**Environment variables**

Add to `.env`:

```bash
GALDAKAO_CENSUS_TLS=true
GALDAKAO_CENSUS_TLS_CERT=/etc/ssl/galdakao/ca.crt
GALDAKAO_CENSUS_TLS_CLIENT_CERT=/etc/ssl/galdakao/decidim-client.crt
GALDAKAO_CENSUS_TLS_CLIENT_KEY=/etc/ssl/galdakao/decidim-client.key
CENSUS_URL=https://api.galdakao.eus/soap
```

**DNS resolution (internal API servers)**

If the API server is on an internal network without public DNS, the container needs to resolve the certificate CN to the internal IP. Add to `docker-compose.yml` under the `app` service:

```yaml
extra_hosts:
  - "api.galdakao.eus:<INTERNAL_IP>"
```

The actual IP is not stored in this repository. Contact the maintainer team for the correct value.

For the full mTLS setup procedure including certificate generation, see `Docs_MD/Hoja de ruta__mTLS.md`.

## Patch: infinite loop in onboarding with unauthorized zone
This installation includes a patch in `config/initializers/decidim_patches.rb` that fixes a **Decidim core bug (#9826)** which causes an infinite redirect loop when a user successfully verifies against the municipal register but their address does not belong to any of the zones required by the permission. For details on the bug, root cause and applied fix, see `\gems\decidim-galdakao_census\Docs_MD\Bug_onboarding_loop_PR.md`.

## Deploy

### Pull from Github Repository

This instance uses Docker Compose to deploy the application into the port 3015.

First, you need to make sure you are logged into the Github Docker registry (ghcr.io).

1. Go to your personal Github account, into tokens settings https://github.com/settings/tokens
2. Generate a new token (Classic)
3. Ensure you check the permission "read:packages" and "No expiration".
4. In the server, login into docker, introduce your username and the token generated:
  ```bash
  docker login ghcr.io --username github-username
  ```
5. You should stay logged permanently, you should not need to repeat this process.

To re-deploy the image this should suffice:

`docker compose up -d`

### Locally building the Docker image

This instance uses Docker Compose to deploy the application with Traefik as a proxy.

> If you want to locally build the docker image, change the line `image: ghcr.io/galdakaoko-udala/erabaki-galdakao:${GIT_REF:-main}` for `image: decidim_${DECIDIM_ENV:-production}` first!

You need to build and tag the image:

1. Ensure you have the ENV value `DECIDIM_ENV=staging` or `DECIDIM_ENV=production`
2. Run:
   `./build.sh`
3. Deploy:
  `docker compose up -d`

## Backups

Database is backup every day using https://github.com/tiredofit/docker-db-backup (see docker-compose.yml for details)

Backups are stored in:

- `backups/*`

## Setting up the application

You will need to do some steps before having the app working properly once you've deployed it:

1. Open a Rails console in the server: `bundle exec rails console`
2. Create a System Admin user:

```ruby
user = Decidim::System::Admin.new(email: <email>, password: <password>, password_confirmation: <password>)
user.save!
```

3. Visit `<your app url>/system` and login with your system admin credentials
4. Create a new organization. Check the locales you want to use for that organization, and select a default locale.
5. Set the correct default host for the organization, otherwise the app will not work properly. Note that you need to include any subdomain you might be using.
6. Fill the rest of the form and submit it.

You're good to go!