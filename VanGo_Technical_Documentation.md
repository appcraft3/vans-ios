# VanGo -- Technical Documentation

## 1. Architecture Overview

VanGo is a trust-based, invite-only van life community app built with a
scalable mobile-first architecture.

### iOS Client

-   **SwiftUI** for UI development
-   **MVVM-C (Model-View-ViewModel-Coordinator)** architecture
-   Coordinator-based navigation wrapping SwiftUI views in UIKit
    containers
-   Modular feature structure (SignIn, Onboarding, Waitlist, Explore,
    Events, Chat, Profile, Builders)
-   Real-time Firestore listeners for live updates (messages, event
    states, matches)
-   **MapKit** for event discovery and geolocation-based browsing
-   **Firebase Cloud Messaging (FCM)** for push notifications

### Backend

-   **Firebase Cloud Functions (TypeScript, Node 20)**
-   **Firestore** as real-time NoSQL database
-   **Firebase Storage** for media (profile photos, event images,
    stories)
-   HTTPS callable functions secured via Firebase Auth
-   Event lifecycle logic handled server-side
-   Backend-triggered mutual interest matching after event completion

------------------------------------------------------------------------

## 2. Authentication & Access Control

-   **Apple Sign-In**
-   **Google Sign-In**
-   Firebase Authentication manages user sessions
-   Role-based system:
    -   `guest`
    -   `waitlist`
    -   `member`
    -   `premium`
-   Additional roles:
    -   `user`
    -   `moderator`
    -   `admin`

Access levels and trust state are enforced both on client UI and backend
Cloud Functions.

------------------------------------------------------------------------

## 3. RevenueCat Implementation

VanGo uses **RevenueCat** to power subscriptions under the product:

### Product

-   **VanGo Pro** (auto-renewable subscription)

### Entitlement

-   `vangopro_access`

### Features Gated by Entitlement

-   Priority waitlist review
-   Verified+ badge (active while subscribed)
-   Enhanced event/map visibility
-   Future role-based access (e.g., premium builder privileges)

### Implementation Details

-   RevenueCat SDK integrated on iOS
-   Subscription state checked via `CustomerInfo.entitlements`
-   Premium access level stored in Firestore for backend enforcement
-   Cloud Functions validate user entitlement before allowing
    premium-only actions
-   UI dynamically updates based on entitlement state
-   Cancellation handled natively through App Store subscription
    management

RevenueCat simplifies: - Receipt validation - Cross-device entitlement
syncing - Subscription lifecycle management

This ensures monetization supports trust and commitment rather than
pay-to-win visibility mechanics.

------------------------------------------------------------------------

## 4. Scalability Considerations

-   All business logic lives in Cloud Functions
-   Client remains thin and state-driven
-   Firestore structured for event subcollections (attendees, interests,
    messages)
-   Matching logic triggered only at event completion to reduce
    real-time complexity
-   Role-based architecture allows future expansion without major
    refactoring

------------------------------------------------------------------------

## 5. Security & Trust Design

-   Invite-code + moderator-based onboarding
-   Backend-enforced access levels
-   Time-limited DMs
-   Event-based connection logic
-   Future AI-assisted moderation pipeline planned

VanGo's architecture prioritizes safety, intentional growth, and
scalability from day one.
