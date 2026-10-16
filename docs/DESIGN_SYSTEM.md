# UI/UX Design System Specification: Aurora Finance (Premium Dark Finance)

## 1. Visual Direction & Brand Philosophy
- **Identity:** Private AI Financial Assistant and Financial Intelligence Center.
- **Aesthetic:** Deep space dark canvas (`#070B12`), luminous cyan/blue atmospheric glows (`#37E8FF`, `#2F80FF`), frosted glass cards (`rgba(255, 255, 255, 0.06)`), and 3D iridescent lighting.
- **Core Stance:** Read-only monitoring layer. Non-custodial, no payment gateways, no banking API credential storage.

---

## 2. Color Palette & Tokens (Figma Ready)

| Token Name | Hex / Value | Usage |
| :--- | :--- | :--- |
| `bg-primary` | `#070B12` | App canvas background |
| `bg-secondary` | `#0B1220` | Secondary surfaces, bottom sheets |
| `surface-elevated`| `#111827` | Popovers, modal dialogues |
| `surface-card` | `#151F2E` | Base card surface fill |
| `surface-glass` | `rgba(255,255,255,0.06)` | Frosted glass containers |
| `accent-primary` | `#2F80FF` | Primary CTA, active icons |
| `accent-cyan` | `#18D5FF` | Glowing highlights, sparkline stroke |
| `accent-soft-blue`| `#6EA8FF` | Secondary accents, chip borders |
| `ai-glow` | `#37E8FF` | AI aura, interactive prompt glows |
| `semantic-income` | `#22C55E` | Income indicators, positive delta |
| `semantic-expense`| `#F05252` | Spending indicators, warnings |
| `semantic-savings`| `#818CF8` | Savings badge, goal progress |
| `text-primary` | `#F8FAFC` | Main balance, headings, titles |
| `text-secondary` | `#CBD5E1` | Card subtext, body copy |
| `text-muted` | `#64748B` | Captions, inactive navigation tabs |
| `border-soft` | `rgba(255,255,255,0.08)` | Default card border |
| `border-active` | `rgba(56,189,248,0.45)` | Focused card, AI insight container |

---

## 3. Typography Scale

- **Large Number (Hero Balance):** 42–48px, SemiBold / Bold, letter-spacing: -1.0px.
- **Page Title:** 28–32px, SemiBold, letter-spacing: -0.5px.
- **Section Title:** 18–20px, SemiBold, letter-spacing: -0.3px.
- **Card Title / Merchant Name:** 15–17px, Medium / SemiBold.
- **Body Text:** 14–15px, Regular, line-height: 1.45.
- **Caption / Subtext:** 12–13px, Regular.
- **Micro Label:** 11–12px, SemiBold, letter-spacing: +0.4px.

---

## 4. Component Matrix

### 4.1 Balance Card
- **Dimensions:** Full width minus 40px margins, padding 20px.
- **Surface:** Linear gradient (`#101C30` to `#0C1424`) with `rgba(47, 128, 255, 0.35)` border.
- **Sparkline Wave:** Bezier cubic spline, stroke 2.4px (`#18D5FF`), 8px gaussian blur under-glow, linear gradient underfill fade to transparent.
- **Privacy Mask:** Tap eye icon to mask balance as `••••••••`.

### 4.2 Metric Pill Card (Income, Spending, Savings)
- **Grid:** 3-column row with 10px spacing.
- **Layout:** Centered circular badge (34x34px) with tinted background (12% opacity), label (12px muted), amount (16px bold).

### 4.3 AI Insight Banner
- **Trigger:** Dynamic anomaly or budget alert.
- **Accent:** 💡 emoji + cyan badge (`AI Insight`), single-sentence observation, circular blue forward CTA button.

### 4.4 3D Iridescent Orb (AI Centerpiece)
- **Construction:** Concentric atmospheric blur halos (`#18D5FF`, `#A855F7`), radial gradient sphere, specular gloss highlight pill with smooth breathing animation.

---

## 5. Microcopy & Communication Guidelines
- **Tone:** Calm, precise, analytical, non-alarmist.
- **Allowed:** «Похоже, это регулярный платёж», «Покупка доступна без риска для обязательных расходов», «Операция требует подтверждения».
- **Prohibited:** «Мы контролируем ваши деньги», «Подключите ваш банк», «Гарантируем экономию».
