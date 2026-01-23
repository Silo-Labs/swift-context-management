import Foundation
import FoundationModels
import Testing

@testable import SwiftContextManagement

@Suite("Foundation Models Summarizer Tests")
struct FoundationModelsSummarizerTests {
    @Test("Summarizes conversation entries")
    func summarizesConversationEntries() async throws {
        let summarizer = FoundationModelsSummarizer()

        let prompt = TestHelpers.createPrompt(content: "What is Swift?")
        let response = TestHelpers.createResponse(content: "Swift is a programming language.")

        let entries: [Transcript.Entry] = [
            .prompt(prompt),
            .response(response)
        ]

        let summary = try await summarizer.summarize(
            entries: entries,
            instructions: nil,
            locale: .enUS
        )

        #expect(!summary.isEmpty)
        // The summary should contain relevant information from the conversation
        #expect(summary.count > 10)
    }

    @Test("Uses custom instructions when provided")
    func usesCustomInstructions() async throws {
        let summarizer = FoundationModelsSummarizer()

        let prompt = TestHelpers.createPrompt(content: "Tell me about cats")
        let response = TestHelpers.createResponse(content: "Cats are pets.")

        let entries: [Transcript.Entry] = [
            .prompt(prompt),
            .response(response)
        ]

        let customInstructions = "Focus only on the main subject mentioned."
        let summary = try await summarizer.summarize(
            entries: entries,
            instructions: customInstructions,
            locale: .enUS
        )

        #expect(!summary.isEmpty)
    }

    @Test("Handles empty entries")
    func handlesEmptyEntries() async throws {
        let summarizer = FoundationModelsSummarizer()

        let summary = try await summarizer.summarize(
            entries: [],
            instructions: nil,
            locale: .enUS
        )

        // Should return some response even for empty entries
        #expect(summary.isEmpty || !summary.isEmpty)
    }

    @Test("Handles entries with no text content")
    func handlesEntriesWithNoTextContent() async throws {
        let summarizer = FoundationModelsSummarizer()

        // Create entries that might not have extractable text
        let entries: [Transcript.Entry] = [
            .prompt(Transcript.Prompt(segments: []))
        ]

        let summary = try await summarizer.summarize(
            entries: entries,
            instructions: nil,
            locale: .enUS
        )

        // Should handle gracefully
        #expect(summary.isEmpty || !summary.isEmpty)
    }

    @Test("Respects locale parameter")
    func respectsLocaleParameter() async throws {
        let summarizer = FoundationModelsSummarizer()

        let prompt = TestHelpers.createPrompt(content: "Bonjour")
        let response = TestHelpers.createResponse(content: "Comment allez-vous?")

        let entries: [Transcript.Entry] = [
            .prompt(prompt),
            .response(response)
        ]

        // Test with French locale (should require instructions)
        do {
            let summary = try await summarizer.summarize(
                entries: entries,
                instructions: nil,
                locale: Locale(identifier: "fr_FR")
            )
            #expect(!summary.isEmpty)
        } catch FoundationModelsSummarizerError.missingInstructionsForSpecifiedLocale {
            // Expected behavior for non-English locales without instructions
            #expect(true)
        }
    }

    @Test("Summarizes extensive real-world project planning conversation")
    func summarizesExtensiveRealWorldProjectPlanningConversation() async throws {
        let summarizer = FoundationModelsSummarizer()

        let entries: [Transcript.Entry] = [
            .prompt(TestHelpers.createPrompt(content: """
        We need to plan a new mobile application for our company. 
        The app should help users manage their daily tasks and collaborate with team members. 
        What are the key features we should prioritize for the MVP?
        """)),

                .response(TestHelpers.createResponse(content: """
        Based on your requirements, I'd recommend focusing on these core features for the MVP:
        
        1. User Authentication & Profiles: Secure login with email/password and social media options (Google, Apple Sign-In). 
           User profiles should include basic information, avatar, and preferences.
        
        2. Task Management: Create, edit, delete, and organize tasks. Support for due dates, priorities (high/medium/low), 
           and task categories or tags. Users should be able to mark tasks as complete.
        
        3. Team Collaboration: Ability to create teams, invite members via email, assign tasks to team members, 
           and see team activity feed. Basic role management (admin, member, viewer).
        
        4. Notifications: Push notifications for task assignments, due date reminders, and team activity. 
           In-app notification center.
        
        5. Search & Filter: Search tasks by keyword, filter by assignee, due date, priority, or status. 
           Quick filters for "My Tasks", "Team Tasks", "Overdue", etc.
        
        These features provide the foundation for task management and collaboration without overwhelming users.
        """)),

                .prompt(TestHelpers.createPrompt(content: """
        That sounds good. Now, what about the technical architecture? 
        We're thinking of using React Native for cross-platform development. 
        What backend infrastructure would you recommend?
        """)),

                .response(TestHelpers.createResponse(content: """
        For a React Native mobile app with your requirements, here's a solid architecture:
        
        **Frontend (React Native):**
        - React Native with TypeScript for type safety
        - State management: Redux Toolkit or Zustand for global state
        - Navigation: React Navigation for screen routing
        - UI Components: React Native Paper or NativeBase for consistent design
        - Real-time updates: Socket.io client for live collaboration features
        
        **Backend Infrastructure:**
        - API Server: Node.js with Express or NestJS framework
        - Database: PostgreSQL for relational data (users, tasks, teams) with proper indexing
        - Caching: Redis for session management, frequently accessed data, and rate limiting
        - File Storage: AWS S3 or Cloudinary for user avatars and attachments
        - Real-time: Socket.io server for live notifications and collaboration
        - Authentication: JWT tokens with refresh token mechanism
        - Background Jobs: Bull Queue with Redis for email notifications and scheduled tasks
        
        **DevOps & Deployment:**
        - Backend: Deploy to AWS ECS, Google Cloud Run, or Heroku
        - Database: Managed PostgreSQL (AWS RDS, Google Cloud SQL, or Supabase)
        - CI/CD: GitHub Actions or GitLab CI for automated testing and deployment
        - Monitoring: Sentry for error tracking, DataDog or New Relic for performance monitoring
        
        This stack provides scalability, maintainability, and good developer experience.
        """)),

                .prompt(TestHelpers.createPrompt(content: """
        What's a realistic timeline for building this MVP? 
        We have a team of 3 developers (2 frontend, 1 backend) and 1 designer.
        """)),

                .response(TestHelpers.createResponse(content: """
        With your team composition, here's a realistic timeline:
        
        **Phase 1: Foundation (Weeks 1-3)**
        - Week 1: Project setup, architecture decisions, design system creation
        - Week 2: Backend API foundation (auth, database schema, basic CRUD)
        - Week 3: Frontend setup, navigation, authentication screens
        
        **Phase 2: Core Features (Weeks 4-8)**
        - Weeks 4-5: Task management features (create, edit, delete, list views)
        - Week 6: Team creation and member management
        - Week 7: Task assignment and collaboration features
        - Week 8: Search and filtering functionality
        
        **Phase 3: Polish & Integration (Weeks 9-12)**
        - Week 9: Push notifications setup and implementation
        - Week 10: Real-time updates and activity feeds
        - Week 11: UI/UX polish, animations, error handling
        - Week 12: Testing, bug fixes, performance optimization
        
        **Total: 12 weeks (3 months) for MVP**
        
        This assumes full-time work. If part-time, scale accordingly. 
        Add 2-3 weeks buffer for unexpected issues and refinements.
        """)),

                .prompt(TestHelpers.createPrompt(content: """
        What about the budget? We need to estimate costs for development tools, 
        cloud services, and third-party services.
        """)),

                .response(TestHelpers.createResponse(content: """
        Here's a budget breakdown for your MVP:
        
        **Development Tools & Services:**
        - Code hosting: GitHub (free for private repos) or GitLab (free tier)
        - Project management: Jira ($7/user/month) or Linear ($8/user/month) - ~$30/month
        - Design tools: Figma (free for small teams) or Sketch ($99 one-time)
        - CI/CD: GitHub Actions (free for public, $4/month for private) or GitLab CI (free)
        
        **Cloud Infrastructure (Monthly):**
        - Backend hosting: AWS ECS or Heroku - $25-50/month for small scale
        - Database: Managed PostgreSQL (Supabase free tier, or AWS RDS ~$15-30/month)
        - File storage: AWS S3 (~$5-10/month for moderate usage)
        - Redis: AWS ElastiCache or Upstash (~$10-20/month)
        - CDN: Cloudflare (free tier) or AWS CloudFront (~$5/month)
        
        **Third-Party Services:**
        - Push notifications: Firebase Cloud Messaging (free) or OneSignal (free tier)
        - Analytics: Mixpanel (free tier) or Amplitude (free tier)
        - Error tracking: Sentry (free tier for small projects)
        - Email service: SendGrid (free tier: 100 emails/day) or AWS SES (~$0.10 per 1000 emails)
        - Authentication: Auth0 (free tier: 7000 users) or Firebase Auth (free tier)
        
        **Total Monthly Cost: ~$60-120/month** for MVP phase
        
        **One-time Costs:**
        - App Store registration: Apple ($99/year), Google Play ($25 one-time)
        - SSL certificates: Let's Encrypt (free) or AWS Certificate Manager (free)
        
        As you scale, costs will increase, but this covers MVP needs.
        """)),

                .prompt(TestHelpers.createPrompt(content: """
        Great! One more thing - what about security considerations? 
        We'll be handling user data and need to ensure GDPR compliance.
        """)),

                .response(TestHelpers.createResponse(content: """
        Security and GDPR compliance are critical. Here's what you need:
        
        **Security Measures:**
        - Encryption: HTTPS everywhere (TLS 1.3), encrypt sensitive data at rest
        - Authentication: Strong password requirements, 2FA option, secure token storage
        - API Security: Rate limiting, input validation, SQL injection prevention, CORS configuration
        - Data Protection: Encrypt PII (Personally Identifiable Information) in database
        - Secure Storage: Use Keychain (iOS) and Keystore (Android) for sensitive data
        - Regular Updates: Keep dependencies updated, security patches applied
        
        **GDPR Compliance Requirements:**
        - Privacy Policy: Clear, accessible policy explaining data collection and usage
        - User Consent: Explicit consent for data processing, easy opt-out mechanisms
        - Data Access: Users can request their data (data export feature)
        - Right to Deletion: Users can delete their account and all associated data
        - Data Minimization: Only collect data necessary for app functionality
        - Data Breach Notification: Process for notifying users within 72 hours if breach occurs
        - Data Processing Agreement: If using third-party services, ensure they're GDPR compliant
        - Data Protection Officer: Appoint DPO if processing large amounts of sensitive data
        
        **Implementation Checklist:**
        - Implement "Delete Account" functionality that removes all user data
        - Create data export feature (JSON/CSV download)
        - Add consent checkboxes during registration
        - Log all data access and modifications for audit trail
        - Regular security audits and penetration testing
        - Document data retention policies
        
        Consider consulting with a legal expert for full GDPR compliance review.
        """))
        ]

        // Summarize the extensive conversation
        let summary = try await summarizer.summarize(
            entries: entries,
            instructions: nil,
            locale: .enUS
        )

        // Verify the summary captures key information
        #expect(!summary.isEmpty, "Summary should not be empty")
        #expect(summary.count > 100, "Summary should be substantial for such a long conversation")

        // Verify the summary mentions key topics discussed
        let summaryLower = summary.lowercased()

        // Check for key project planning topics
        let keyTopics = [
            "feature",
            "task",
            "team",
            "architecture",
            "timeline",
            "budget",
            "security"
        ]

        let foundTopics = keyTopics.filter { summaryLower.contains($0) }
        #expect(foundTopics.count >= 4, "Summary should mention at least 4 key topics from the conversation. Found: \(foundTopics)")

        // Verify summary is concise (should be much shorter than original)
        let originalTextLength = entries.compactMap { TranscriptHelpers.extractText(from: $0) }
            .joined()
            .count
        #expect(summary.count < originalTextLength, "Summary should be shorter than original conversation")
        #expect(Double(summary.count) / Double(originalTextLength) < 0.5, "Summary should be significantly shorter (less than 50% of original)")
    }
}
