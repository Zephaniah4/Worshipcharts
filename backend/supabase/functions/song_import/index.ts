// Supabase Edge Function stub: song import queue endpoint.
// Replace with provider SDK/API calls that comply with each provider's terms.

Deno.serve(async (req: Request) => {
  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 });
  }

  const body = await req.json().catch(() => null);
  if (body == null || body.provider == null || body.query == null) {
    return new Response(JSON.stringify({ error: 'provider and query are required' }), {
      status: 400,
      headers: { 'content-type': 'application/json' },
    });
  }

  const response = {
    status: 'queued',
    provider: String(body.provider),
    query: String(body.query),
    note: 'Implement provider-specific, licensed import pipeline in background worker.',
  };

  return new Response(JSON.stringify(response), {
    status: 202,
    headers: { 'content-type': 'application/json' },
  });
});
