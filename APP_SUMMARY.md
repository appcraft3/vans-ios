# VanGo - App Summary & Feature Guide

## What is VanGo?

VanGo is a trusted community app for van lifers. It connects people who live, travel, or are planning the van life — through events, real-time messaging, and a reputation-based trust system. The app is invite-only with a waitlist to maintain community quality.

---

## App Flow Overview

```
Launch → Splash → Sign In → Onboarding (5 steps) → Waitlist / Invite Code → Main App
```

**Access Levels:**
- **Guest** — Just signed in, needs to complete profile
- **Waitlist** — Profile complete, pending admin approval or invite code
- **Member** — Approved, full access to the app
- **Premium (VanGo Pro)** — Subscription active, priority features unlocked

---

## Screens & Features

### 1. Splash Screen

The app launch screen. Checks authentication, refreshes tokens, loads user data, and verifies app version. If the app is outdated, a force-update overlay directs the user to the App Store. On error, a retry option is shown.

---

### 2. Sign In

Two authentication options:
- **Sign in with Apple**
- **Sign in with Google**

Clean, minimal screen with the VanGo logo and a "Welcome to VANS" headline. Handles cancellation gracefully without showing errors.

---

### 3. Onboarding (5 Steps)

New users complete a progressive registration flow with a road-lane styled progress bar:

1. **Full Name** — Text input for the user's name
2. **Birthday** — Wheel date picker with age verification (must be 18+)
3. **Gender** — Button grid selection (male, female, other) with haptic feedback; auto-advances on tap
4. **Languages** — Flow-layout multi-select from 20 supported languages (English, Spanish, French, German, Portuguese, Italian, Dutch, Polish, Russian, Turkish, Japanese, Chinese, Korean, Arabic, Hindi, Swedish, Norwegian, Danish, Finnish, Czech)
5. **Social Media** — Optional Instagram username input; can skip

After completing onboarding, the profile is submitted and the user enters the waitlist flow.

---

### 4. Waitlist / Invite Code Screen

Shown to users who completed onboarding but haven't been approved yet.

**What the user sees:**
- Community values cards and trust explanation
- Waitlist position (e.g., "#42 in line")
- Application status (pending, approved, rejected, on hold)
- "Join Waitlist" button to submit for review
- "Have an invite code?" collapsible input for immediate access
- **"Skip the wait with Pro"** card — opens the paywall for priority review
- Sign out option

**Behind the scenes:**
- Status polls every 30 seconds
- Auto-routes to the main app when approved
- Invite code redemption bypasses the waitlist

---

### 5. Main App — 4 Tabs

The main app has a custom frosted-glass tab bar with 4 tabs:

| Tab | Icon | Label |
|-----|------|-------|
| 1 | binoculars.fill | Explore |
| 2 | calendar.circle.fill | Events |
| 3 | message.fill | Messages |
| 4 | person.fill | Profile |

---

### Tab 1: Explore

The discovery hub with a dark-themed map and stories.

**Stories Section (top):**
- Horizontal scrollable story bubbles with green progress rings
- Add story button with photo picker (compresses to 1080px, JPEG 0.8 quality)
- Stories expire after 24 hours
- Tap any story to view full-screen with the poster's name and time ago
- Auto-refreshes every 60 seconds

**Map Section:**
- Full-screen dark-styled MapKit map
- Event annotations as pins on the map
- Tap a pin to see an event preview card at the bottom
- Tap the preview to open full event detail
- Location recenter button (top-right)

**Filters:**
- Search bar to search locations (opens location search sheet)
- Horizontal activity filter chips: All, Hiking, Surfing, Climbing, Cycling, Kayaking, Photography, Yoga, Cooking, Stargazing, Remote Work
- Filters apply to map annotations in real-time

---

### Tab 2: Events

Browse and interact with community events in a swipeable card stack.

**Event Cards:**
- Stacked card layout (shows 3 cards at once)
- Swipe up to dismiss / move to next card
- Each card shows: cover photo, status badge (Upcoming/Ongoing/Completed/Cancelled), activity icon, title, date, location, attendee count, heart/interest button
- "All caught up" state when all cards are viewed

**Filters:**
- Date filter chips: All, Today, This Week, Next Week, Later
- Location filter button for region/country filtering

**Create Event** (admin/moderator only):
- Multi-photo upload (up to 10, first = cover)
- Title and description
- Activity type selection (horizontal chips)
- Location search with Apple Maps integration
- Start and end date/time pickers
- Max attendees stepper
- Check-in toggle (for attendance confirmation)
- Photo compression: resized to 1200px, JPEG 70% quality

---

### Event Detail Screen

Full event details with two tabs: **Details** and **Chat**.

**Details Tab:**
- Hero image with green gradient overlay
- Status badge and activity type badge
- Info pills: date, location, attendee count
- About/description section
- Photo gallery (horizontal scroll)
- Attendees section with profile cards

**Attendee Interactions:**
- Tap attendee to view their full profile
- Send interest to attendees (up to 5 per event)
- Interest counter shows remaining (e.g., "3/5 interests")

**Check-in System:**
- During ongoing events, users enter a check-in code to confirm attendance
- Code is issued by the event organizer/admin

**Admin Controls:**
- Enable check-in (marks event as ongoing)
- Issue/refresh check-in codes
- Complete event (enables review writing)

**Reviews:**
- After an event is completed, attendees can write reviews for each other
- Reviews build trust scores and are visible on profiles

**Chat Tab:**
- Real-time group chat for the event
- Firestore-powered live messaging
- Date separators, message timestamps
- Tap avatar to view user profile

---

### Tab 3: Messages

Chat hub for event-based connections.

**Chat List:**
- Shows all active matches/connections from events
- Each row: profile photo, name, last message preview, timestamp, unread count
- Event source badge (which event the connection is from)
- Status indicators: waiting for response, expired, premium badge
- Pull-to-refresh
- Empty state: "No matches yet"

**One-on-One Chat:**
- Real-time messaging powered by Firestore listeners
- Optimistic message sending (appears instantly, confirms in background)
- Message pagination (load more history)
- Read receipts (checkmark icon)
- Date separators (Today, Yesterday, older dates)
- Gender-based messaging: women message first in some contexts
- "Waiting for her to message" status banner when applicable

**Match Popup:**
- When two users express mutual interest at an event, a celebration modal appears
- "It's a Match!" headline with the event name
- Animated profile photo with staggered entrance animations
- Two actions: "Send Message" or "Keep Browsing"

---

### Tab 4: Profile

User's personal profile with glass-card design and starfield background.

**Profile Header:**
- Profile photo (120x120) with camera badge for editing
- Photo upload with progress indicator (compressed to 500px, JPEG 70%)
- "Go Pro" button (top-right) or "VanGo Pro" badge if subscribed

**Profile Info:**
- Name, age, van-life status badge (Full-Time / Part-Time / Planning)
- Connections count
- Instagram link (opens in browser)

**Community Activity Section:**
- Events attended count
- Review count
- Trust badges (Event Participant, Verified, Trusted Member, Trusted Builder)

**Interests Section:**
- Activity icons with names in a flowing chip layout

**Bio Section:**
- User's bio text

**Builder Mode:**
- Toggle to become a community builder
- Opens builder application form

**Builder Application:**
- Category multi-select grid (e.g., electrical, plumbing, carpentry, etc.)
- Bio text editor (20 character minimum)
- Availability declaration
- Checks if user is already a builder

**My Reviews:**
- List of reviews received from other community members
- Shows reviewer name, avatar, event context, and review text

**Admin Features** (admin role only):
- Waitlist Review panel — approve or reject pending users
- Each pending user shows: photo, name, age, location, van-life status, bio, activities
- Approve/Reject buttons with animated list updates

**Settings:**
- Sign out button

---

### Paywall — VanGo Pro

Full-screen subscription screen with starfield background and glassmorphic design.

**Header:**
- Mountain icon
- "Unlock VanGo Pro"
- "Priority access, better visibility, and community perks — all in one subscription."

**Feature Cards** (horizontal carousel):

| Icon | Title | Description |
|------|-------|-------------|
| bolt.shield | Priority Review | Skip the wait and get approved faster |
| checkmark.seal.fill | Verified+ Badge | Badge stays active while subscribed |
| chart.line.uptrend.xyaxis | Visibility Boost | Higher placement in events and map |
| headset | Priority Support | Faster support and review times |

**Benefits Checklist:**
- Skip the long wait (priority review)
- Verified+ badge while subscribed
- Better visibility in Events & Explore
- Cancel anytime

**Plan Selector:**
- Monthly plan — price per month
- Yearly plan — price per year, shows monthly equivalent, "Save X%" or "Best Value" badge
- Yearly is pre-selected by default

**CTA Button:**
- "Join VanGo Pro" — full-width green button

**Footer:**
- "Auto-renews. Cancel anytime in Settings."
- "Restore Purchases" link

**Paywall Entry Points:**
- Profile tab → "Go Pro" button (top-right)
- Waitlist/Invite Code screen → "Skip the wait with Pro" card

---

## Trust & Reputation System

VanGo uses a trust-based system to keep the community safe:

- **Trust Level** — Increases with positive interactions
- **Badges** earned through participation:
  - Event Participant — Attended events
  - Verified — Identity verified
  - Trusted Member — Consistent positive reviews
  - Trusted Builder — Verified builder with completed sessions
- **Events Attended** — Total count visible on profile
- **Reviews** — Written by other attendees after events; positive and negative counts tracked
- **Premium Status** — Visible badge for VanGo Pro subscribers

---

## Event Interest & Matching System

1. Users browse events and mark interest (heart button)
2. At events, users can send interest to other attendees (up to 5 per event)
3. If both users express mutual interest → **Match**
4. Match triggers a celebration popup with the event name
5. Matched users can message each other
6. DMs have an expiration window
7. Gender-based messaging rules: women message first in applicable contexts

---

## Technical Architecture

- **Pattern:** MVVM-C (Model-View-ViewModel-Coordinator)
- **UI Framework:** SwiftUI views wrapped in UIKit coordinators via UIHostingController
- **Backend:** Firebase (Auth, Firestore, Cloud Functions)
- **Real-time:** Firestore listeners for chat, matches, and user data
- **Subscriptions:** RevenueCat SDK
- **Auth Providers:** Google Sign-In, Apple Sign-In
- **Maps:** MapKit with dark styling and geocoding
- **Image Loading:** Kingfisher
- **Design:** Dark theme (#121212), glassmorphic cards, accent green (#2E7D5A)

---

## Paywall Copy (Full Text)

### Headline
> Unlock VanGo Pro

### Subtitle
> Priority access, better visibility, and community perks — all in one subscription.

### Feature Cards
> **Priority Review** — Skip the wait and get approved faster
> **Verified+ Badge** — Badge stays active while subscribed
> **Visibility Boost** — Higher placement in events and map
> **Priority Support** — Faster support and review times

### Benefits
> - Skip the long wait (priority review)
> - Verified+ badge while subscribed
> - Better visibility in Events & Explore
> - Cancel anytime

### CTA
> Join VanGo Pro

### Footer
> Auto-renews. Cancel anytime in Settings.
> Restore Purchases

### Waitlist Pro Prompt (InviteCodeView)
> **Skip the wait with Pro**
> Get priority review and join faster
