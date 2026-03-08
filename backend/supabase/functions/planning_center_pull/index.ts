// Supabase Edge Function stub: Planning Center pull endpoint.

Deno.serve(async (req: Request) => {
  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 });
  }

  const body = await req.json().catch(() => null);
  if (body == null || body.planId == null) {
    return new Response(JSON.stringify({ error: 'planId is required' }), {
      status: 400,
      headers: { 'content-type': 'application/json' },
    });
  }

  return new Response(
    JSON.stringify({
      status: 'accepted',
      planId: String(body.planId),
      note: 'Implement OAuth token lookup, API call, and song matching logic.',
    }),
    {
      status: 202,
      headers: { 'content-type': 'application/json' },
    },
  );
});
