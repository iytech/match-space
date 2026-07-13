# Email Notifications — Setup

Match Space sends an email whenever a user gets an in-app notification (new
message, viewing request, booking update, listing approved/rejected). This
reuses the `notifications` table — you don't wire up events again.

The flow: a row is inserted into `notifications` → a database webhook calls the
`send-notification-email` Edge Function → the function emails the user via
Resend.

## 1. Get a Resend API key (free)

1. Sign up at https://resend.com (free tier: 100 emails/day, 3,000/month).
2. Create an API key (API Keys → Create).
3. For testing you can send **from** `onboarding@resend.dev` to **your own**
   email immediately. To send to *any* address and from your own domain, add
   and verify your domain in Resend (Domains → Add). Start with the test
   address to prove it works, then verify a domain before real users.

## 2. Add secrets in Supabase

Dashboard → Project Settings → Edge Functions → (Secrets), add:

| Name             | Value                                   |
|------------------|-----------------------------------------|
| `RESEND_API_KEY` | your Resend key                         |
| `FROM_EMAIL`     | `onboarding@resend.dev` (or your domain)|
| `APP_URL`        | `https://matchspacez.netlify.app`       |

`SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` are provided automatically to
Edge Functions — you don't add those.

## 3. Deploy the function

Install the Supabase CLI if you haven't (https://supabase.com/docs/guides/cli),
then from the project root:

```
supabase login
supabase link --project-ref pvmvvsdxhynalscksdqj
supabase functions deploy send-notification-email
```

## 4. Connect it to the notifications table

In the Supabase dashboard → **Database → Webhooks** → Create a new webhook:

- **Name:** email-on-notification
- **Table:** `notifications`
- **Events:** Insert
- **Type:** Supabase Edge Function
- **Function:** `send-notification-email`

Save. Now every new notification triggers an email.

> Alternative (SQL, if you prefer triggers over the webhook UI): you can call
> the function via `pg_net` from an AFTER INSERT trigger on `notifications`.
> The webhook UI is simpler and recommended.

## 5. Test

- Sign in as two users, have one message the other.
- The recipient gets an in-app notification **and** an email (to the address on
  their profile).
- If no email arrives: check the function logs (Edge Functions → Logs). Common
  causes: `RESEND_API_KEY` not set, sending to a non-verified address while
  still on the test domain, or the profile has no email.

## Notes

- Emails never block in-app notifications. If email fails, the bell still works.
- The service-role key stays server-side in the function — never in the app.
- To reduce email volume later, you could add a user preference to opt out, or
  only email for high-signal events (messages, bookings) and skip others.
