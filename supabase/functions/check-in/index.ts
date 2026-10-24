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

function safeEqual(a: string, b: string) {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return diff === 0;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });

  const auth = req.headers.get("Authorization");
  if (!auth) return json({ error: "unauthorized" }, 401);

  const userDb = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: auth } } },
  );
  const adminDb = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  // Only staff can check guests in. RLS lets a user see only their own row.
  const { data: staff } = await userDb.from("staff").select("user_id").maybeSingle();
  if (!staff) return json({ error: "not_staff" }, 403);

  const { token } = await req.json().catch(() => ({}));
  const parts = typeof token === "string" ? token.split(".") : [];
  if (parts.length !== 4 || parts[0] !== "bmg1") return json({ error: "invalid_qr" }, 400);

  const [, id, expStr, sig] = parts;
  const expected = await hmacHex(Deno.env.get("QR_SIGNING_SECRET")!, `${id}.${expStr}`);
  if (!safeEqual(expected, sig)) return json({ error: "invalid_qr" }, 400);

  const exp = Number(expStr);
  if (!Number.isFinite(exp) || exp < Date.now() / 1000) return json({ error: "expired" }, 409);

  const { data: appt } = await adminDb
    .from("appointments")
    .select("id,user_id,status,start_at,stylist_name,service_names,payment_method,payment_status,total")
    .eq("id", id)
    .maybeSingle();
  if (!appt) return json({ error: "invalid_qr" }, 404);

  if (appt.status === "checked_in" || appt.status === "in_service" || appt.status === "completed") {
    return json({ error: "already_used" }, 409);
  }
  if (appt.status !== "confirmed") return json({ error: "not_confirmed" }, 409);

  const startsInMs = new Date(appt.start_at).getTime() - Date.now();
  if (startsInMs > 60 * 60 * 1000) return json({ error: "too_early" }, 409);

  // Atomic: only one scan can flip confirmed to checked_in.
  const { data: updated } = await adminDb
    .from("appointments")
    .update({ status: "checked_in", checked_in_at: new Date().toISOString() })
    .eq("id", id)
    .eq("status", "confirmed")
    .select("id")
    .maybeSingle();
  if (!updated) return json({ error: "already_used" }, 409);

  const { data: profile } = await adminDb
    .from("profiles").select("full_name").eq("id", appt.user_id).maybeSingle();

  return json({
    id: appt.id,
    customer: profile?.full_name ?? "Guest",
    stylist: appt.stylist_name,
    services: appt.service_names,
    start_at: appt.start_at,
    payment_method: appt.payment_method,
    payment_status: appt.payment_status,
    total: appt.total,
  });
});