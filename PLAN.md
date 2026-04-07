# Library Card 1.0 - App Development Plan

## Concept Summary

A Strava-meets-fintech iOS app that gives users an Apple Wallet payment card (prepaid or linked to a credit card). When users pay with the card, the app automatically tracks purchases and provides rich statistics on drinking behavior: drinks per hour, spending trends, session recaps, monthly reports, venue analytics, and more.

---

## Part 1: Can You Create a Custom Card for Apple Wallet?

### Short Answer: Yes, but with caveats.

There are **two very different things** in Apple Wallet:

| Type | What It Is | Who Can Create It |
|------|-----------|-------------------|
| **Wallet Passes** (loyalty, gift, event, coupon, generic) | Informational cards with barcodes. Do NOT tap-to-pay. | Any developer with a $99/yr Apple Developer account via PassKit. |
| **Apple Pay Payment Cards** (debit, credit, prepaid) | Real payment cards that work at NFC terminals. | Only licensed card issuers with Apple Pay certification and In-App Provisioning entitlement. |

### What You Actually Need

To issue a real payment card that appears in Apple Wallet and works at tap-to-pay terminals, you need:

1. **A Card Issuing Platform** (handles the banking/payment network side)
2. **Apple's In-App Provisioning Entitlement** (allows the "Add to Apple Wallet" button in your app)
3. **Payment Network Certification** (Visa/Mastercard -- handled by the issuing platform)

### Recommended Card Issuing Platforms

| Platform | Best For | Apple Pay Support | Pricing |
|----------|---------|-------------------|---------|
| **Lithic** (Recommended) | Indie devs / early startups | Yes, via provisioning API | ~$0.10/virtual card, no monthly fees, self-serve |
| **Stripe Issuing** | Teams already using Stripe | Yes, via Stripe SDK | No upfront cost; contact Sales for live mode |
| **Marqeta** | Funded startups / enterprise | Yes, via provisioning API | Enterprise pricing, not public |

### The Apple Provisioning Bottleneck

Even with Lithic/Stripe issuing the card, you still need Apple to grant the **In-App Provisioning entitlement** (`com.apple.developer.payment-pass-provisioning`). This requires:
- Emailing `apple-pay-provisioning@apple.com`
- Apple reviewing and approving your app concept
- Standard App Store distribution (no Enterprise accounts)

**Workaround if denied:** Users can still manually add the card to Apple Wallet via Wallet > Add Card by entering the card number. You lose the slick "Add to Wallet" button but the card still works.

### Feasibility Summary

| Goal | Difficulty | Notes |
|------|-----------|-------|
| Issue a real prepaid card | **Moderate** | Lithic Starter: self-serve, ~1 day setup |
| Add card to Apple Wallet programmatically | **Hard** | Requires Apple entitlement approval |
| Add card to Apple Wallet manually | **Easy** | User enters card number in Wallet app |
| Track transactions in real-time | **Easy** | All platforms provide webhooks |
| Pass App Store review | **Moderate** | Need proper disclosures + licensed banking partner |

---

## Part 2: App Architecture Plan

### Tech Stack

| Layer | Technology | Rationale |
|-------|-----------|-----------|
| **iOS App** | SwiftUI + Swift | Modern, declarative, native Apple Wallet/Charts integration |
| **Data Persistence** | SwiftData | Native SwiftUI integration, low boilerplate, sufficient for this data volume |
| **Charts** | Swift Charts (Apple) | Built-in, SwiftUI-native, covers bar/line/area charts |
| **Backend API** | Node.js (Fastify) or Python (FastAPI) | Real-time webhook handling, transaction processing |
| **Database** | PostgreSQL + TimescaleDB extension | ACID-compliant for financial data; time-series optimized for analytics queries |
| **Cache / Real-time** | Redis | Session state, live counters, rate limiting |
| **Auth** | OAuth 2.0 + JWT + Face ID/Touch ID | Industry standard; biometric via Apple LocalAuthentication |
| **Card Issuing** | Lithic API (Starter tier) | Self-serve, cheapest, developer-friendly |

### App Architecture Pattern

```
MVVM + Repository Pattern

View (SwiftUI) --> ViewModel (@Observable) --> Repository --> API Service / SwiftData
```

---

## Part 3: Feature Breakdown & Build Phases

### Phase 1: Core App Shell (Weeks 1-3)

**Goal:** Basic app with manual drink logging and session tracking.

- [ ] Xcode project setup (SwiftUI, iOS 17+)
- [ ] Data models in SwiftData:
  - `User` (profile, preferences)
  - `Session` (start time, end time, venue, status)
  - `Drink` (type, size, price, timestamp, session reference)
  - `Venue` (name, location, visit count)
- [ ] Session tracking flow:
  1. "Start Session" button (optionally set venue or auto-detect via GPS)
  2. Quick-add drinks (favorites, search, custom)
  3. Live dashboard during session (drink count, pace, total spend)
  4. "End Session" (manual or auto after 2hr inactivity)
- [ ] Post-session summary card (Strava-style)
- [ ] Basic tab navigation: Home / Log / Stats / Profile
- [ ] Authentication (Sign in with Apple + Face ID for app re-entry)

### Phase 2: Statistics & Analytics (Weeks 4-6)

**Goal:** Rich data visualization and insights.

- [ ] Dashboard with Swift Charts:
  - Drinks per hour ("pace") line chart
  - Weekly/monthly drink count bar chart
  - Spending trend line chart
  - Drink type breakdown (pie/donut)
  - Day-of-week heatmap
  - Top venues by visit count and spend
- [ ] Session history list with filtering (date, venue, spend)
- [ ] Streaks and milestones:
  - Dry day streaks
  - Consecutive moderate nights
  - Monthly personal records
- [ ] Month-over-month comparisons
- [ ] Aggregate stats: avg drinks/session, avg spend/session, total spend

### Phase 3: Backend & Card Integration (Weeks 7-12)

**Goal:** Issue a real card and auto-track purchases.

- [ ] Backend API setup:
  - User registration/authentication endpoints
  - Transaction ingestion from webhooks
  - Analytics query endpoints
- [ ] Lithic integration:
  - Account creation flow
  - Card issuance (virtual first, then physical)
  - Fund loading (bank transfer or linked credit card)
  - Apple Wallet provisioning (or manual add fallback)
- [ ] Transaction webhook handler:
  - Receive `issuing_authorization.created` events
  - Parse merchant data (name, category code, location)
  - Auto-categorize as drink purchase using MCC codes (5813 = Bars/Taverns, 5812 = Restaurants)
  - Create `Drink` records from transactions
  - Push notification to user: "Logged: $8.50 at The Pub"
- [ ] Smart drink detection:
  - MCC-based filtering (bars, restaurants, liquor stores)
  - User confirmation flow for ambiguous purchases
  - Manual override (mark as drink / not a drink)
- [ ] Sync engine: local SwiftData <-> backend PostgreSQL

### Phase 4: Polish & App Store Submission (Weeks 13-16)

- [ ] Onboarding flow (app walkthrough, card setup)
- [ ] Settings: notification preferences, privacy controls, export data
- [ ] Legal:
  - Terms of Service
  - Privacy Policy (critical for financial data)
  - Identify banking partner (Lithic's sponsor bank)
  - Health disclaimers for BAC estimates
- [ ] App Store assets (screenshots, description, preview video)
- [ ] TestFlight beta testing
- [ ] App Store submission

---

## Part 4: Key Statistics & Metrics

### Per-Session Metrics
- Total drinks consumed (count + standard units)
- **Drinks per hour** ("pace") -- the signature metric
- Total spend + per-drink breakdown
- Session duration
- Drink type breakdown (beer / wine / spirits / cocktails)
- Venue(s) visited
- Estimated BAC (with health disclaimers)
- Calories from alcohol

### Aggregate / Trend Metrics
- Weekly / monthly / yearly totals (drinks, spend, sessions)
- Average drinks per session + trend line
- Average spend per session + trend line
- Day-of-week heatmap
- Drink type distribution over time
- Top venues by visits and spend
- Dry day streaks (gamification)
- Month-over-month comparisons
- Money spent vs. a user-set budget
- "Year in Review" annual report

### Strava-Inspired Features
| Strava Concept | Library Card Equivalent |
|---------------|----------------------|
| Activity recording | Session recording ("Start Night Out" -> log drinks -> "End Session") |
| Pace / Speed | Drinks per hour |
| Distance | Total spend or total units consumed |
| Segments / PRs | Venue records ("biggest night at Bar X") |
| Weekly summaries | Weekly drink + spend summaries |
| Streaks | Dry day streaks, consecutive moderate nights |
| Year in Review | Annual drinking + spending report |
| Training load | Rolling average (drinks/week trend) |

---

## Part 5: Transaction Data Available from Card Issuer

When a user taps their card, the webhook provides:

| Field | Description |
|-------|-------------|
| `amount` | Transaction amount (smallest currency unit) |
| `currency` | Currency code |
| `merchant_data.name` | Merchant name (e.g., "The Irish Pub") |
| `merchant_data.category_code` | MCC code (5813 = Bars, 5812 = Restaurants) |
| `merchant_data.city` | Merchant city |
| `merchant_data.country` | Merchant country |
| `created` | Unix timestamp |
| `wallet` | Whether Apple Pay was used |
| `card` | Which card was used |

This data is rich enough to auto-detect bar/restaurant purchases and create drink log entries automatically.

---

## Part 6: App Store Compliance

### Requirements for Financial Apps
1. Must work with a **licensed financial institution** (Lithic's sponsor bank satisfies this)
2. Must clearly disclose your banking partner in the app
3. Must have a proper **Privacy Policy** and **Terms of Service**
4. Must be transparent about fees
5. Financial data requires strong encryption (TLS 1.3, at-rest encryption)
6. Longer review times expected -- plan for 2-4 weeks

### Data Privacy
- Financial transaction data is PII -- encrypt everything
- Comply with PCI-DSS requirements (mostly handled by Lithic/Stripe)
- GDPR compliance if serving EU users
- Biometric data (Face ID) never leaves device (Apple handles this)

---

## Part 7: Market Opportunity

### Existing Competition
| App | Focus | Gap |
|-----|-------|-----|
| DrinkControl | Drink tracking + calories | No real-time session concept, no card integration |
| Reframe / Sunnyside | Alcohol reduction / sobriety | Health-focused, not for casual social use |
| Alcogram | Daily alcohol tracker | Very basic, no spending analytics |

**Key differentiator:** No existing app combines Strava-style session tracking with real payment card integration for automatic purchase logging. The manual logging problem is the #1 pain point -- this app solves it with the card.

---

## Part 8: Recommended Development Order

```
1. SwiftUI app shell + manual drink logging (prove the UX)
2. Statistics dashboard (prove the value)
3. Backend API + database
4. Lithic card issuing integration
5. Transaction webhook -> auto drink logging
6. Apple Wallet provisioning
7. Polish, legal, App Store submission
```

**MVP Strategy:** Launch Phase 1+2 first (manual logging + stats) as a free app. This validates the concept and builds a user base before investing in the card infrastructure (Phase 3). The card integration becomes the premium upgrade.

---

## Quick Start: Next Steps

1. **Create the Xcode project** with SwiftUI, targeting iOS 17+
2. **Define SwiftData models** (User, Session, Drink, Venue)
3. **Build the session tracking flow** (Start -> Log Drinks -> End -> Summary)
4. **Sign up for Lithic Starter** (free sandbox) to test card issuing
5. **Request Apple In-App Provisioning entitlement** early (can take weeks)
