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

  const b = await req.json().catch(() => ({}));
  const { appointment_id, razorpay_order_id, razorpay_payment_id, razorpay_signature } = b;
  if (!appointment_id || !razorpay_order_id || !razorpay_payment_id || !razorpay_signature) {
    return json({ error: "bad_request" }, 400);
  }

  const expected = await hmacHex(
    Deno.env.get("RAZORPAY_KEY_SECRET")!,
    `${razorpay_order_id}|${razorpay_payment_id}`,
  );
  if (!safeEqual(expected, razorpay_signature)) {
    return json({ error: "bad_signature" }, 400);
  }

  // Confirm the caller owns this appointment and the order matches it.
  const { data: appt } = await userDb
    .from("appointments")
    .select("id,status,razorpay_order_id")
    .eq("id", appointment_id)
    .maybeSingle();
  if (!appt || appt.razorpay_order_id !== razorpay_order_id) {
    return json({ error: "not_found" }, 404);
  }
  if (appt.status === "confirmed") return json({ status: "confirmed" });

  const { data: updated } = await adminDb
    .from("appointments")
    .update({
      status: "confirmed",
      payment_status: "paid",
      razorpay_payment_id,
      hold_expires_at: null,
    })
    .eq("id", appointment_id)
    .eq("status", "pending_payment")
    .select("id")
    .maybeSingle();

  // Paid after the hold expired: money was taken but the slot was released.
  if (!updated) return json({ error: "hold_expired_contact_support" }, 409);
  return json({ status: "confirmed" });
});