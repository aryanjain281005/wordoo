# Parent report email

Grown-up Dashboard → **Email the full report**: the parent enters an email, ticks consent, taps **Send report now**.
After consent is given the report is also sent automatically after every later check-in.

Flow: app (`lib/engine/parent_report.dart` builds the numbers) → `POST /report/email` (`server/src/index.js`) →
Gemini writes the report (`server/src/report.js`: system prompt, JSON schema) → server checks it (numbers must equal the app's,
no diagnostic words; one retry, then a plain template report) → HTML + text email → mail provider.

Mail provider (in the git-ignored `.env`):

    RESEND_API_KEY=re_...            # https://resend.com (free tier)
    MAIL_FROM=Wordoo <reports@yourdomain.com>   # a verified domain; without one Resend only delivers to your own account email

With no `RESEND_API_KEY` the server runs in **dry-run**: the email is saved as an HTML file in `server/outbox/` and the app says so.

Privacy: the parent's address stays on the phone and is only used for the send; the server stores only its domain, the report
text and the numbers (collection `reports`). One report per address per minute. Reports never diagnose; the disclaimer is fixed.
