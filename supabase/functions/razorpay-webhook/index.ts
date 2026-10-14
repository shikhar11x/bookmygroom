import { createClient } from "npm:@supabase/supabase-js@2";

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
  const raw = await req.text();
  const signature = req.headers.get("x-razorpay-signature") ?? "";
  const expected = await hmacHex(Deno.env.get("RAZORPAY_WEBHOOK_SECRET")!, raw);
  if (!safeEqual(expected, signature)) return new Response("bad signature", { status: 400 });

  const event = JSON.parse(raw);
  if (event.event !== "payment.captured" && event.event !== "order.paid") {
    return new Response("ignored", { status: 200 });
  }

  const payment = event.payload?.payment?.entity;
  if (!payment?.order_id) return new Response("ignored", { status: 200 });

  const db = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const { data: appt } = await db
    .from("appointments")
    .select("id,total,status")
    .eq("razorpay_order_id", payment.order_id)
    .maybeSingle();
  if (!appt) return new Response("unknown order", { status: 200 });

  // Amount must match what we asked Razorpay to charge.
  if (payment.amount !== appt.total * 100) return new Response("amount mismatch", { status: 200 });

  if (appt.status === "pending_payment") {
    await db.from("appointments").update({
      status: "confirmed",
      payment_status: "paid",
      razorpay_payment_id: payment.id,
      hold_expires_at: null,
    }).eq("id", appt.id).eq("status", "pending_payment");
  }
  // Razorpay retries on non-2xx, so always return 200 once handled.
  return new Response("ok", { status: 200 });
});