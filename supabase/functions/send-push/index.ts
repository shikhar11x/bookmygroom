import { createClient } from "npm:@supabase/supabase-js@2";
import { importPKCS8, SignJWT } from "npm:jose@5";

function safeEqual(a: string, b: string) {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return diff === 0;
}

function serviceAccount() {
  const raw = atob(Deno.env.get("FIREBASE_SA_B64")!);
  return JSON.parse(raw);
}

let cached: { token: string; exp: number } | null = null;

async function accessToken(sa: any) {
  const now = Math.floor(Date.now() / 1000);
  if (cached && cached.exp - 60 > now) return cached.token;
  const key = await importPKCS8(sa.private_key, "RS256");
  const jwt = await new SignJWT({
    scope: "https://www.googleapis.com/auth/firebase.messaging",
  })
    .setProtectedHeader({ alg: "RS256", typ: "JWT" })
    .setIssuer(sa.client_email)
    .setSubject(sa.client_email)
    .setAudience("https://oauth2.googleapis.com/token")
    .setIssuedAt(now)
    .setExpirationTime(now + 3600)
    .sign(key);
  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });
  if (!res.ok) throw new Error("oauth_failed");
  const d = await res.json();
  cached = { token: d.access_token, exp: now + d.expires_in };
  return cached.token;
}

const fmt = (iso: string) =>
  new Date(iso).toLocaleString("en-IN", {
    timeZone: "Asia/Kolkata",
    weekday: "short",
    day: "numeric",
    month: "short",
    hour: "numeric",
    minute: "2-digit",
  });

function messageFor(op: string, rec: any, old: any) {
  if (op === "REMINDER") {
    return {
      title: "Your appointment is in about an hour",
      body: `${fmt(rec.start_at)} with ${rec.stylist_name}. Tap to see your pass.`,
    };
  }
  if (op === "INSERT") {
    return rec.status === "confirmed"
      ? {
        title: "Booking confirmed",
        body: `${fmt(rec.start_at)} with ${rec.stylist_name}.`,
      }
      : null;
  }
  if (!old || old.status === rec.status) return null;
  switch (rec.status) {
    case "confirmed":
      return {
        title: "Payment received",
        body: `Your booking for ${fmt(rec.start_at)} is confirmed.`,
      };
    case "checked_in":
      return {
        title: "You're checked in",
        body: "We'll let you know when it's your turn.",
      };
    case "in_service":
      return {
        title: "Your service is starting",
        body: `${rec.stylist_name} is ready for you.`,
      };
    case "completed":
      return {
        title: "How was your visit?",
        body: "Tap to rate your service and stylist.",
      };
    default:
      return null;
  }
}

Deno.serve(async (req) => {
  const secret = req.headers.get("x-push-secret") ?? "";
  if (!safeEqual(secret, Deno.env.get("PUSH_WEBHOOK_SECRET") ?? "")) {
    return new Response("unauthorized", { status: 401 });
  }

  const { op, record, old_record } = await req.json().catch(() => ({}));
  if (!record) return new Response("ignored", { status: 200 });

  const db = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
  const sa = serviceAccount();

  async function sendTo(
    userId: string,
    title: string,
    body: string,
    appointmentId: string,
  ) {
    const { data: rows } = await db
      .from("device_tokens")
      .select("token")
      .eq("user_id", userId);
    if (!rows?.length) return;
    const bearer = await accessToken(sa);
    for (const { token } of rows) {
      const res = await fetch(
        `https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`,
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${bearer}`,
          },
          body: JSON.stringify({
            message: {
              token,
              notification: { title, body },
              data: { appointment_id: appointmentId },
              android: { priority: "high" },
            },
          }),
        },
      );
      if (res.status === 404 || res.status === 400) {
        const err = await res.text();
        if (err.includes("UNREGISTERED") || err.includes("INVALID_ARGUMENT")) {
          await db.from("device_tokens").delete().eq("token", token);
        }
      }
    }
  }

  try {
    const msg = messageFor(op, record, old_record);
    if (msg) await sendTo(record.user_id, msg.title, msg.body, record.id);

    if (op === "UPDATE" && record.status === "in_service" &&
        old_record?.status !== "in_service") {
      const day = String(record.start_at).slice(0, 10);
      const nextDay = new Date(`${day}T00:00:00Z`);
      nextDay.setUTCDate(nextDay.getUTCDate() + 1);
      const { data: nxt } = await db
        .from("appointments")
        .select("id,user_id")
        .eq("branch_name", record.branch_name)
        .eq("status", "checked_in")
        .gte("start_at", `${day}T00:00:00Z`)
        .lt("start_at", nextDay.toISOString())
        .order("checked_in_at", { ascending: true })
        .limit(1)
        .maybeSingle();
      if (nxt) {
        await sendTo(
          nxt.user_id,
          "You're next",
          "Please stay nearby. Your stylist will call you shortly.",
          nxt.id,
        );
      }
    }
  } catch (_) {
    // Never fail the webhook; booking must not break.
  }
  return new Response("ok", { status: 200 });
});