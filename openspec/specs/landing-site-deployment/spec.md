### Requirement: Static hosting on Cloudflare Pages

The landing site SHALL be hosted on Cloudflare Pages and served over HTTPS at a dedicated custom domain.

#### Scenario: Served over HTTPS at the custom domain

- **WHEN** a user requests the landing site's production domain
- **THEN** Cloudflare Pages SHALL serve the static assets over HTTPS

#### Scenario: Deployable output is static

- **WHEN** the site is deployed
- **THEN** the deployable output SHALL consist of static files (HTML/CSS/JS) plus Cloudflare Pages Functions, with no long-running application server

### Requirement: Same-origin release manifest proxy

The site SHALL expose a same-origin endpoint that returns the release manifest, so the page can resolve download links without depending on cross-origin access to the download host.

#### Scenario: Proxy returns the manifest same-origin

- **WHEN** the client requests the `/api/latest` endpoint
- **THEN** a Pages Function SHALL fetch `https://dl.enjoy.bot/player/latest.json` and return its JSON from the site's own origin

#### Scenario: Edge caching with revalidation

- **WHEN** clients request `/api/latest` repeatedly within the cache window
- **THEN** the endpoint SHALL serve an edge-cached response with a short TTL and revalidate in the background (stale-while-revalidate)

### Requirement: Automated deploy pipeline

The site SHALL be deployed to Cloudflare Pages by the Pages project's Git integration, with production deploys from the main branch.

#### Scenario: Production deploy on main

- **WHEN** a commit that changes `landing/**` lands on the main branch
- **THEN** the Cloudflare Pages Git integration SHALL deploy the site to the Cloudflare Pages production environment

### Requirement: Caching and security headers

The site SHALL serve appropriate caching and security headers for static and dynamic responses.

#### Scenario: HTML revalidates while static assets cache long

- **WHEN** the site serves its responses
- **THEN** HTML responses SHALL be sent with revalidate-on-load caching and fingerprinted static assets SHALL be sent with long-lived immutable caching

#### Scenario: Security headers present

- **WHEN** any page is served
- **THEN** responses SHALL include a `Content-Security-Policy`, `X-Content-Type-Options: nosniff`, and a `Referrer-Policy` header

### Requirement: Deploy credentials are not committed

Deployment SHALL authenticate to Cloudflare through the Cloudflare Pages GitHub app connection, with no Cloudflare credentials stored in the repository.

#### Scenario: No credential in the repository

- **WHEN** the site is deployed from the main branch
- **THEN** Cloudflare SHALL pull the repository through its GitHub app, and no Cloudflare credential SHALL be present in the repository

### Requirement: Independence from the Flutter app

The landing site SHALL be independent of the Flutter application and SHALL NOT introduce a Flutter web target.

#### Scenario: No Flutter web scaffolding

- **WHEN** the landing site is added to the repository
- **THEN** it SHALL live outside the Flutter app sources (not under `web/`) and SHALL NOT add a Flutter web target or a `kIsWeb` branch

#### Scenario: Deploys without building the app

- **WHEN** the landing site is deployed
- **THEN** the deploy SHALL succeed without building the Flutter application
