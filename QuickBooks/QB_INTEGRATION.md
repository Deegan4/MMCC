# QuickBooks Online Integration

## OAuth 2.0 Flow
MMCC iOS → ASWebAuthenticationSession → Intuit OAuth → Auth Code
Auth Code → Cloudflare Worker (token exchange) → Access + Refresh tokens
Tokens stored in BusinessProfile (SwiftData)

## Why Server Relay
Client secret cannot live on device. Cloudflare Worker handles token exchange + refresh only.

## What Syncs
| Data | Direction | Endpoint |
|------|-----------|----------|
| Customers | Bi-directional | GET/POST /v3/company/{realmId}/customer |
| Products/Services | Pull | GET /v3/company/{realmId}/query?query=SELECT * FROM Item |
| Estimates | Push | POST /v3/company/{realmId}/estimate |
| Invoices | Push | POST /v3/company/{realmId}/invoice |
| Payments | Push | POST /v3/company/{realmId}/payment |
| Tax Rates | Pull | GET /v3/company/{realmId}/query?query=SELECT * FROM TaxRate |

## Costs
- POST operations: FREE under Intuit pricing
- GET operations: 500K/month CorePlus quota (more than enough)

## Section Mapping
QB has no native sections. Map via DescriptionOnly + SubTotalLineDetail lines:
- "--- PILINGS / FOUNDATION ---" (DescriptionOnly)
- Line items...
- SubTotal line
- "--- DECKING / FRAMING ---" (DescriptionOnly)
- etc.

## Token Lifecycle
- Access: 60 min expiry, silent refresh
- Refresh: 100 days, prompt re-auth if expired

## Intuit App Store
List on apps.intuit.com. Submit for review at start of Week 3 (1-2 week review).

## Error Handling
- 401: refresh token, re-auth if refresh fails
- 429: exponential backoff
- 500+: queue for retry (max 3)
- Network down: SyncQueueItem, process when online
