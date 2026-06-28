const UPSTREAM = 'https://dl.enjoy.bot/player/latest.json';

/**
 * Same-origin proxy for the release manifest.
 * Serves the manifest from this origin so the client never hits dl.enjoy.bot
 * directly, and the edge can apply its own caching policy.
 */
export async function onRequest(_context) {
  let upstream;
  try {
    upstream = await fetch(UPSTREAM, {
      cf: {
        cacheTtl: 300,
        cacheEverything: true,
      },
    });
  } catch {
    return errorResponse(502, 'Failed to reach the download host.');
  }

  if (!upstream.ok) {
    return errorResponse(upstream.status, 'Upstream returned an error.');
  }

  let body;
  try {
    body = await upstream.text();
  } catch {
    return errorResponse(502, 'Failed to read upstream response.');
  }

  return new Response(body, {
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
      // Edge: cache 5 min, serve stale for up to 10 min while revalidating.
      'Cache-Control': 'public, max-age=300, stale-while-revalidate=600',
    },
  });
}

function errorResponse(status, message) {
  return new Response(JSON.stringify({ error: message }), {
    status,
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
      'Cache-Control': 'no-store',
    },
  });
}
