# SharkEstate — API Design (v1 sketch)

REST under `/api/v1`, org resolved from session (`Membership.isDefault` or
`X-Org-Id` header). All bodies validated with Zod. Errors:

```json
{ "error": { "code": "VALIDATION_ERROR", "message": "...", "fieldErrors": {} } }
```

Codes: `VALIDATION_ERROR` 400 · `UNAUTHENTICATED` 401 · `FORBIDDEN` 403 ·
`NOT_FOUND` 404 · `CONFLICT` 409 (e.g. two active leases on one unit) ·
`RATE_LIMITED` 429.

## Resources

| Method | Path | Notes |
|---|---|---|
| GET/POST | `/properties` | list paginated, create |
| GET/PATCH/DELETE | `/properties/:id` | delete only if no units w/ history |
| GET/POST | `/properties/:id/units` | bulk create supported |
| PATCH | `/units/:id` | status transitions validated server-side |
| GET/POST | `/tenants` | unique per org on phone |
| GET/POST | `/leases` | create → DRAFT; activate via subresource |
| POST | `/leases/:id/activate` | tx: one ACTIVE lease per unit |
| POST | `/leases/:id/terminate` | requires notice period check |
| GET | `/leases/:id/invoices` | history for this lease |
| GET/POST | `/invoices` | manual creation; bulk run is the cron |
| POST | `/invoices/:id/void` | reason required, audit-logged |
| GET/POST | `/payments` | manual entry (cash/bank/mpesa-receipt) |
| POST | `/payments/mpesa/stkpush` | returns CheckoutRequestID |
| POST | `/webhooks/mpesa` | Daraja callback, idempotent, raw stored |
| GET/POST | `/maintenance` | tickets |
| PATCH | `/maintenance/:id` | status machine validated |
| GET | `/reports/rent-roll` | CSV/PDF |
| GET | `/reports/arrears` | aging buckets 1–30/31–60/60+ |
| GET | `/reports/owner-statement` | params: propertyId, month |
| POST | `/jobs/daily` | cron-authenticated, idempotent |

## Pagination & filtering

Cursor pagination (`?cursor=&limit=`, default 25). Filters as query params:
`status=`, `propertyId=`, `q=` (server-side search on label/name/phone).
Invoices/payments lists always include derived `balance` per invoice.

## Conventions

- Money fields serialized as **strings** (`"45000.00"`) — never floats in JSON.
- Dates ISO-8601 UTC; the client renders in `Africa/Nairobi`.
- All mutating endpoints write an `AuditLog` entry in the same transaction.
- Webhook endpoints authenticate via Daraja security credentials; jobs via
  `CRON_SECRET` bearer; never session-auth.
