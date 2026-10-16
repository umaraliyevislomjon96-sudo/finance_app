# Security Architecture & Threat Model: Aurora Finance

## 1. Zero-Knowledge Financial Monitoring Principles

1. **Strictly Non-Custodial:**
   - The application does NOT execute payment commands, funds transfers, or account withdrawals.
   - The application does NOT request or store online banking passwords, 2FA credentials, or open banking API secrets.
2. **Card Data Protections (PCI-DSS Scoping Avoidance):**
   - Full 16-digit Primary Account Numbers (PAN) are NEVER stored in any database, cache, or client storage.
   - Card Verification Values (CVV/CVC) and Card ATM PINs are NEVER requested, parsed, or retained.
   - Only `first4` and `last4` identifiers are saved to identify bank card sources (`8600 •••• •••• 4821`).
3. **Multi-Tenant User Isolation:**
   - Every database query strictly isolates records by `user_id`.
   - PostgreSQL Row-Level Security (RLS) policies prevent cross-tenant data leaks.

---

## 2. Authentication & Session Security

- **Mobile Device Storage:**
  - iOS: Hardware Keychain backed by Secure Enclave with `kSecAccessControlBiometryAny`.
  - Android: EncryptedSharedPreferences backed by Android Keystore (hardware-backed Keystore / StrongBox).
- **Application PIN Protection:**
  - App PINs are hashed using PBKDF2-HMAC-SHA256 with 100,000 iterations and a cryptographically secure 16-byte salt.
  - Brute force lockout: 5 consecutive failed PIN attempts trigger a mandatory 15-minute lock.
- **JWT Token Rotation:**
  - Short-lived Access Tokens (15 minutes).
  - Refresh tokens stored in hashed format (SHA-256) with device ID binding.
  - One-tap remote revocation ("Log out all devices").

---

## 3. Data Privacy & Notification Ingestion Safety

- Ingestion webhook endpoints sanitize notification payloads, discarding any sensitive OTP authentication codes (e.g., "Ваш код для входа: 1234").
- Users retain the right to complete GDPR/CCPA account deletion (`DELETE /api/v1/auth/me`), which performs a cascading deletion across all cards, transactions, and audit trails.
