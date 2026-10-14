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

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });

  const auth = req.headers.get("Authorization");
  if (!auth) return json({ error: "unauthorized" }, 401);

  // User-scoped client: row level security limits this to the caller's rows.
  const userDb = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: auth } } },
  );
  const adminDb = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const { appointment_id } = await req.json().catch(() => ({}));
  if (!appointment_id) return json({ error: "bad_request" }, 400);

  const { data: appt } = await userDb
    .from("appointments")
    .select("id,total,status,hold_expires_at,razorpay_order_id")
    .eq("id", appointment_id)
    .maybeSingle();

  if (!appt) return json({ error: "not_found" }, 404);
  if (appt.status !== "pending_payment") return json({ error: "not_payable" }, 409);
  if (new Date(appt.hold_expires_at) < new Date()) return json({ error: "hold_expired" }, 409);

  const keyId = Deno.env.get("RAZORPAY_KEY_ID")!;
  const keySecret = Deno.env.get("RAZORPAY_KEY_SECRET")!;

  // Reuse the order if the user retries within the hold window.
  if (appt.razorpay_order_id) {
    return json({ order_id: appt.razorpay_order_id, amount: appt.total * 100, key_id: keyId });
  }

  const res = await fetch("https://api.razorpay.com/v1/orders", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: "Basic " + btoa(`${keyId}:${keySecret}`),
    },
    body: JSON.stringify({
      amount: appt.total * 100, // paise, always from the database
      currency: "INR",
      receipt: appt.id,
    }),
  });
  if (!res.ok) return json({ error: "gateway_error" }, 502);
  const order = await res.json();

  await adminDb
    .from("appointments")
    .update({ razorpay_order_id: order.id })
    .eq("id", appt.id);

  return json({ order_id: order.id, amount: order.amount, key_id: keyId });
});