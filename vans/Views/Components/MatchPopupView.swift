import SwiftUI

struct MatchPopupView: View {
    let match: MatchInfo
    let onSendMessage: () -> Void
    let onDismiss: () -> Void

    @State private var showContent = false
    @State private var showPhoto = false
    @State private var showButtons = false

    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.85)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 24) {
                Spacer()

                // Title
                VStack(spacing: 8) {
                    Text("It's a Match!")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(AppTheme.primary)

                    Text("You and \(match.otherUserName) liked each other at")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)

                    Text(match.eventName)
                        .font(.headline)
                        .foregroundColor(AppTheme.secondary)
                }
                .opacity(showContent ? 1 : 0)
                .scaleEffect(showContent ? 1 : 0.8)

                // Profile photo
                CachedProfileImage(url: match.otherUserPhotoUrl, size: 140)
                    .overlay(
                        Circle()
                            .stroke(AppTheme.primary, lineWidth: 3)
                    )
                    .shadow(color: AppTheme.primary.opacity(0.4), radius: 20)
                    .opacity(showPhoto ? 1 : 0)
                    .scaleEffect(showPhoto ? 1 : 0.5)

                Text(match.otherUserName)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.textPrimary)
                    .opacity(showPhoto ? 1 : 0)

                Spacer()

                // Buttons
                VStack(spacing: 12) {
                    Button(action: onSendMessage) {
                        Text("Send Message")
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppTheme.primary)
                            .cornerRadius(14)
                    }

                    Button(action: onDismiss) {
                        Text("Keep Browsing")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
                .opacity(showButtons ? 1 : 0)
                .offset(y: showButtons ? 0 : 30)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                showContent = true
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2)) {
                showPhoto = true
            }
            withAnimation(.easeOut(duration: 0.3).delay(0.5)) {
                showButtons = true
            }
        }
    }
}
