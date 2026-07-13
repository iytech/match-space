// ============================================================================
// Supabase Edge Function: send-notification-email
// Sends an email via Resend whenever a new row is inserted into `notifications`.
//
// SETUP (see EMAIL_SETUP.md for full steps):
//   1. Create a free account at resend.com and get an API key.
//   2. In Supabase: Settings -> Edge Functions -> Secrets, add:
//        RESEND_API_KEY = your key
//        FROM_EMAIL     = onboarding@resend.dev  (or your verified domain)
//        APP_URL        = https://matchspacez.netlify.app
//   3. Deploy:  supabase functions deploy send-notification-email
//   4. Add a DB webhook (or trigger) on `notifications` INSERT that calls this
//      function. See EMAIL_SETUP.md.
//
// The function receives the inserted notification row, looks up the user's
// email, and sends a formatted message. Failures are logged but never block
// the in-app notification (which already succeeded).
// ============================================================================

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY")!;
const FROM_EMAIL = Deno.env.get("FROM_EMAIL") ?? "onboarding@resend.dev";
const APP_URL = Deno.env.get("APP_URL") ?? "";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const admin = createClient(SUPABASE_URL, SERVICE_ROLE);

Deno.serve(async (req) => {
  try {
    const payload = await req.json();
    // Supabase DB webhooks send { type, table, record, ... }
    const n = payload.record ?? payload;
    if (!n || !n.user_id) {
      return new Response("no record", { status: 200 });
    }

    // Look up the recipient's email.
    const { data: profile } = await admin
      .from("profiles")
      .select("email, full_name")
      .eq("id", n.user_id)
      .maybeSingle();

    const to = profile?.email;
    if (!to) return new Response("no email", { status: 200 });

    const name = profile?.full_name ?? "there";
    const link = n.route ? `${APP_URL}/#${n.route}` : APP_URL;

    const html = `
      <div style="font-family:system-ui,sans-serif;max-width:520px;margin:0 auto;padding:24px;">
        <div style="display:inline-flex;align-items:center;gap:8px;margin-bottom:20px;">
          <div style="width:32px;height:32px;border-radius:9px;background:#C75B39;
               display:flex;align-items:center;justify-content:center;color:#fff;font-size:18px;">&#9962;</div>
          <span style="font-size:19px;font-weight:700;color:#1B1E22;">Match Space</span>
        </div>
        <h1 style="font-size:20px;color:#1B1E22;margin:0 0 8px;">${escape(n.title)}</h1>
        <p style="font-size:15px;color:#5A6068;line-height:1.6;margin:0 0 24px;">
          Hi ${escape(name)},<br>${escape(n.body)}
        </p>
        <a href="${link}" style="display:inline-block;background:#C75B39;color:#fff;
           text-decoration:none;padding:12px 24px;border-radius:12px;font-weight:700;">
           Open Match Space</a>
        <p style="font-size:12px;color:#9AA0A8;margin-top:32px;">
          You're receiving this because you have a Match Space account.
        </p>
      </div>`;

    const res = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${RESEND_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: `Match Space <${FROM_EMAIL}>`,
        to: [to],
        subject: n.title,
        html,
      }),
    });

    if (!res.ok) {
      console.error("Resend error:", await res.text());
      return new Response("email failed", { status: 200 });
    }
    return new Response("sent", { status: 200 });
  } catch (e) {
    console.error("function error:", e);
    return new Response("error", { status: 200 });
  }
});

function escape(s: string): string {
  return (s ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;");
}
