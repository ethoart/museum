# Museum Site

Primary production host: AWS
Backup host: Render

This repository currently keeps the museum source snapshot in `museame-github-source.zip` and includes a Render Blueprint that automatically unpacks, builds, and publishes the site.

## Render backup deployment

1. In Render, create a new **Blueprint** and connect this GitHub repository.
2. Render reads `render.yaml`.
3. The build script `scripts/render-build.sh` extracts `museame-github-source.zip`.
4. If the project is Node/Vite/React-based, it installs dependencies and runs the existing `npm run build` command.
5. The script publishes the first supported production output directory it finds: `dist`, `build`, or `out`.
6. For a plain static site, it publishes the folder containing `index.html`.

The Render service name is configured as `dewmanthi-museum-backup`.

## Failover architecture

Recommended setup:

- AWS stays the primary production host.
- Render stays online as the secondary host.
- Route 53 uses a health check against the AWS endpoint.
- Primary DNS record points to AWS.
- Secondary failover record points to the Render custom domain or Render hostname.
- When AWS becomes unhealthy, Route 53 serves the Render target.
- When AWS becomes healthy again, traffic returns to AWS.

## Important

Do not keep persistent uploads or application data only on a local Render filesystem. Persistent museum assets and data should live in shared storage such as S3 or Supabase so both AWS and Render can load the same content.

## Next improvement

The preferred repository layout is to extract the source archive into normal Git-tracked files instead of keeping the app inside a ZIP. That makes code review, CI, Render builds, and future deployments easier.
