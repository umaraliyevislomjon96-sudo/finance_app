# Transaction Parser Engine Specification: Uzbekistan & Universal Formats

## 1. Architectural Pipeline

```
[ Incoming SMS / Push Notification ]
                │
                ▼
      [ Normalization Layer ]
(Strip zero-width spaces, unify currency symbols: UZS/сум/so'm)
                │
                ▼
   [ Bank Template Parsers ]
├── 1. ClickNotificationParser (SMS/Push from CLICK)
├── 2. PaymeNotificationParser (SMS/Push from Payme)
├── 3. UzumBankParser (Apelsin/Uzum notifications)
├── 4. UzcardHumoGatewayParser (Gateways 7557, 0808)
└── 5. UniversalInternationalParser (Visa, MC, Apple Pay)
                │
         (If No Match)
                ▼
     [ Regex Fallback Parser ]
                │
                ▼
     [ Confidence Scoring Engine ]
(Evaluates parsed tokens: amount, currency, direction, card, merchant)
                │
                ▼
  [ Deduplication & Hash Verification ]
sha256(user_id:amount:currency:card_last4:merchant:time_bucket_5m)
                │
                ▼
   [ Correlation & Linking Engine ]
├── Refund Detector (matches past expense within 30 days)
└── Internal Transfer Detector (matches opposing tx within 3 min)
                │
                ▼
        [ Database Storage ]
(status: 'confirmed' if score >= 0.85, else 'needs_review')
```

---

## 2. Confidence Scoring Algorithm

| Token Extracted | Weight Points |
| :--- | :--- |
| Exact transaction amount identified | `+0.35` |
| Valid currency code recognized (UZS, USD, EUR, etc.) | `+0.15` |
| Direction determined (income, expense, transfer, refund) | `+0.20` |
| Card last 4 digits identified | `+0.15` |
| Merchant / Terminal name identified | `+0.15` |
| **Maximum Total Score** | **1.00** |

- **Score >= 0.85:** Automatically marked as `confirmed`.
- **Score 0.60 – 0.84:** Placed in the **Review Queue** (`needs_review`) for quick user one-tap validation.
- **Score < 0.60:** Tagged as `ignored` or recorded as unstructured log without polluting charts.

---

## 3. Deduplication Logic
Duplicate notifications frequently occur when a user receives both a native banking push and an SMS from gateway 7557 for the same transaction.
- Duplicate Hash Formula:
  `sha256(f"{user_id}:{amount:.2f}:{currency}:{card_last4 or 'none'}:{normalized_merchant}:{epoch_mins // 5}")`
- If an identical hash is recorded within the 5-minute window, the transaction status is set to `duplicate_candidate` and excluded from dashboard totals.
