# Whisper Rings — Email Flow Copy

Paste-ready automated emails for Klaviyo / Shopify Email. These run on autopilot and
bring buyers back at **zero ad cost** — your highest-margin sales.

> Brand voice: warm, elegant, confident — never crude. Replace `[brackets]`.
> Merge tags shown in Klaviyo style (`{{ first_name }}`) — adjust if using Shopify Email.

**Flows in this doc**
1. Welcome (popup signup) — 3 emails
2. Abandoned cart — 3 emails
3. Browse abandonment — 1 email
4. Post-purchase — 2 emails
5. Review request — 1 email
6. Win-back — 2 emails

---

## 1. Welcome Flow (triggers on email signup)
*Goal: convert a new subscriber into a first order.*

### Email 1.1 — send immediately
> **Subject:** Welcome to Whisper Rings 🤍 (here's 15% off)
> **Preview:** Your code's inside — plus fast US shipping in ~1 week.
>
> Hi {{ first_name|default:"there" }},
>
> Welcome to Whisper Rings — lingerie made to make you feel confident, beautiful, and
> entirely yourself.
>
> As a thank-you for joining, here's **15% off your first order**:
>
> ### `WHISPER15`
>
> [Shop the collection →]
>
> 🚚 Fast US shipping (~1 week) · 🔒 Discreet packaging · 📏 True-fit size guide
>
> With love,
> Whisper Rings

### Email 1.2 — send 24h later (if no purchase)
> **Subject:** Where to start 💕
> **Preview:** Our most-loved pieces — and how to pick your perfect fit.
>
> Hi {{ first_name|default:"there" }},
>
> Not sure where to begin? These are the pieces our community reaches for first:
>
> - **[Aria Lace Bralette Set]** — soft, everyday confidence
> - **[Noir Mesh Bodysuit]** — bold but effortless
> - **[Lumière Babydoll]** — flattering on every shape
>
> 💡 **One tip:** our styles run a little small — when in doubt, size up. Our
> [Size Guide] takes the guesswork out.
>
> Your **15% off** with `WHISPER15` is still waiting.
>
> [Shop now →]

### Email 1.3 — send 48h later (if no purchase)
> **Subject:** Your 15% off is about to expire ⏳
> **Preview:** Don't miss it — fast US shipping, discreet every time.
>
> Hi {{ first_name|default:"there" }},
>
> Just a gentle reminder — your welcome offer won't last forever.
>
> Use **`WHISPER15`** for 15% off, with fast US shipping (~1 week) and discreet
> packaging on every order.
>
> [Claim your 15% off →]
>
> Here whenever you're ready 🤍

---

## 2. Abandoned Cart Flow (triggers on add-to-cart, no checkout)
*Goal: recover the "almost" buyers — often your best ROI emails.*

### Email 2.1 — send 1 hour after abandonment
> **Subject:** You left something lovely behind 💕
> **Preview:** Your cart's still here — and so is your size.
>
> Hi {{ first_name|default:"there" }},
>
> Your pieces are still waiting in your cart:
>
> {{ cart_items }}
>
> [Complete my order →]
>
> 🚚 Fast US shipping (~1 week) · 🔒 Discreet packaging

### Email 2.2 — send 24h later (if still no purchase)
> **Subject:** Still thinking it over? 🤍
> **Preview:** Here's a little something to help you decide.
>
> Hi {{ first_name|default:"there" }},
>
> Your cart's still here — and to help you decide, here's **10% off**:
>
> ### `COMEBACK10`
>
> {{ cart_items }}
>
> [Finish checkout →]
>
> 💡 Not sure on size? Ours run small — size up if you're between. [Size Guide]

### Email 2.3 — send 48h later (final nudge)
> **Subject:** Last chance — your cart's about to expire ⏳
> **Preview:** 10% off + fast US shipping, before it's gone.
>
> Hi {{ first_name|default:"there" }},
>
> This is the last reminder for the pieces in your cart. Stock on our favorites moves
> quickly, and your **`COMEBACK10`** code expires soon.
>
> {{ cart_items }}
>
> [Complete my order →]
>
> With love, Whisper Rings

---

## 3. Browse Abandonment (triggers on product view, no add-to-cart)
*Goal: re-engage window-shoppers. Keep it soft — they didn't commit yet.*

### Email 3.1 — send ~4h after browsing
> **Subject:** Still on your mind? 👀
> **Preview:** The piece you were eyeing — plus a few you'll love.
>
> Hi {{ first_name|default:"there" }},
>
> You were admiring **{{ viewed_product }}** — and we don't blame you.
>
> [Take another look →]
>
> Pair it with one of these and make it a set:
> {{ product_recommendations }}
>
> 🚚 Fast US shipping (~1 week) · 🔒 Discreet packaging

---

## 4. Post-Purchase Flow (triggers on order placed)
*Goal: reassure, reduce "where's my order?" tickets, set up the review.*

### Email 4.1 — send immediately after purchase
> **Subject:** Thank you 🤍 Your Whisper Rings order is confirmed
> **Preview:** Here's what happens next.
>
> Hi {{ first_name }},
>
> Thank you for your order — we're so glad you're here.
>
> **What happens next:**
> - We're preparing your order now (ships in 1–2 business days).
> - You'll get a tracking email the moment it's on its way.
> - Most US orders arrive in **about a week**.
> - It'll arrive in **plain, discreet packaging** — always.
>
> Order #{{ order_number }} · [View order →]
>
> 💡 A note on fit: our pieces run small, so if anything feels snug, size up next time.
> For hygiene reasons, intimate apparel is final sale — but if anything arrives
> defective or incorrect, just reply to this email within 48 hours and we'll make it right.
>
> With love, Whisper Rings

### Email 4.2 — send 2 days after delivery
> **Subject:** How's your Whisper Rings? 💕
> **Preview:** We'd love to hear from you.
>
> Hi {{ first_name }},
>
> Your order should have arrived by now — we hope you love it! 🤍
>
> A few ways we're here for you:
> - Questions about fit or styling? Just reply — a real person answers.
> - Loved it? We'd be honored if you shared a review (next one's below).
>
> Thank you for supporting a small brand. It means the world.

---

## 5. Review Request (triggers ~5–7 days after delivery)
*Goal: collect photo reviews — your most powerful future-sales engine.*

### Email 5.1
> **Subject:** Mind sharing your thoughts? (10% off as thanks) 💕
> **Preview:** Your review helps others find their perfect fit.
>
> Hi {{ first_name }},
>
> We'd love to know how you're loving your **{{ product_name }}**.
>
> Your honest review — bonus points for a photo! — helps other women find their fit
> and supports our little brand more than you know.
>
> [Leave a review →]
>
> As a thank-you, here's **10% off your next order**: `THANKYOU10`
>
> With gratitude, Whisper Rings

---

## 6. Win-Back Flow (triggers ~30–45 days after last purchase)
*Goal: bring lapsed buyers back. Pure-margin repeat sales.*

### Email 6.1 — send ~30 days after last order
> **Subject:** We've been thinking of you 🤍
> **Preview:** New arrivals you'll love — plus a little welcome-back gift.
>
> Hi {{ first_name }},
>
> It's been a little while — and we've added some beautiful new pieces we think are
> *so* you.
>
> {{ new_arrivals }}
>
> Here's **15% off** to treat yourself: `MISSYOU15`
>
> [Shop new arrivals →]
>
> 🚚 Fast US shipping (~1 week) · 🔒 Discreet packaging

### Email 6.2 — send 5 days later (if no purchase)
> **Subject:** Your 15% off expires soon ⏳
> **Preview:** A last little nudge — with love.
>
> Hi {{ first_name }},
>
> Just a reminder that your **`MISSYOU15`** code is about to expire. We'd love to see
> you again.
>
> [Shop now →]
>
> Always here when you need us 🤍 Whisper Rings

---

## Setup notes

- **Discount codes used:** `WHISPER15` (welcome/win-back), `COMEBACK10` (cart),
  `THANKYOU10` (review thanks), `MISSYOU15` (win-back). Create these in Shopify →
  Discounts, set sensible expiries and a minimum spend to protect margin.
- **Stagger sends** so a buyer isn't in two flows at once (exclude purchasers from
  cart/welcome flows once they convert).
- **Mobile-first:** short subject lines (~30–40 chars), one clear button, single column.
- **Compliance:** include your business name, address, and an unsubscribe link in the
  footer of every email (CAN-SPAM). Most ESPs add these automatically.
- **Keep imagery tasteful** in emails too — some inboxes/filters flag explicit content.
- **Test each flow** by triggering it yourself before going live.
