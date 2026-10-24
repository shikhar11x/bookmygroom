import { createClient } from "npm:@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, content-type, apikey",
};
const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });

async function hmacHex(secret: string, message: string) {
  const key = await crypto.subtle.importKey(
    "raw", new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" }, false, ["sign"],
  );
  const sig = await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(message));
  return [...new Uint8Array(sig)].map((b) => b.toString(16).padStart(2, "0")).join("");
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });

  const auth = req.headers.get("Authorization");
  if (!auth) return json({ error: "unauthorized" }, 401);

  // User-scoped client: row level security means only the owner can read it.
  const userDb = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: auth } } },
  );

  const { appointment_id } = await req.json().catch(() => ({}));
  if (!appointment_id) return json({ error: "bad_request" }, 400);

  const { data: appt } = await userDb
    .from("appointments")
    .select("id,status,end_at")
    .eq("id", appointment_id)
    .maybeSingle();

  if (!appt) return json({ error: "not_found" }, 404);
  if (appt.status !== "confirmed") return json({ error: "not_confirmed" }, 409);

  const exp = Math.floor(new Date(appt.end_at).getTime() / 1000);
  if (exp < Date.now() / 1000) return json({ error: "expired" }, 409);

  const sig = await hmacHex(Deno.env.get("QR_SIGNING_SECRET")!, `${appt.id}.${exp}`);
  return json({ token: `bmg1.${appt.id}.${exp}.${sig}` });
});