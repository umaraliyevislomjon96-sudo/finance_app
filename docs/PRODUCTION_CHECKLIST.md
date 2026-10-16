# Production Readiness & Deployment Checklist: Aurora Finance

## 1. Backend Infrastructure & Scaling
- [x] **PostgreSQL 16 Partitioning & Indexing:** Optimized indexes on `(user_id, occurred_at DESC)`, `(user_id, duplicate_hash)`.
- [x] **Redis Layer:** Caching active parsed merchant dictionary and rate-limiting limits.
- [x] **Containerization:** Production Dockerfile and `docker-compose.yml` with health checks.
- [ ] **Observability:** Prometheus metrics endpoint, Sentry error tracking, OpenTelemetry tracing.
- [ ] **Automated Backups:** Daily WAL-G / pg_dump snapshots to encrypted S3 / Cloud Storage with 30-day retention.

## 2. Mobile App (iOS & Android)
- [x] **Design System Fidelity:** 1:1 match with dark fintech mockup (Glowing 3D Orb, Bezier wave sparkline, Frosted glass cards).
- [x] **Biometric Integration:** `local_auth` integration for Face ID / Touch ID / Fingerprint unlock.
- [x] **Hardware Keystore:** `flutter_secure_storage` storing tokens and PIN salts.
- [ ] **Android Notification Listener:** Declared in AndroidManifest with permission `BIND_NOTIFICATION_LISTENER_SERVICE` and explicit user disclosure prompt.
- [ ] **App Store Privacy Manifest:** iOS Privacy Nutrition Label: Financial Data linked to user for app functionality only; no tracking across 3rd-party apps.

## 3. Security & Compliance
- [x] **No Card Details:** Zero storage of CVV, PIN, or full card numbers.
- [x] **Rate Limiting:** OTP requests limited to 3 per 10 minutes per phone number.
- [x] **Brute-Force Lockout:** PIN locked after 5 failed attempts.
- [x] **Account Deletion:** User data deletion endpoint compliant with Apple App Store Review Guideline 5.1.1(v).
