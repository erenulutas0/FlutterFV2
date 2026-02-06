# MVP Architecture Report

## 📋 Executive Summary

This document provides a comprehensive overview of the VocabMaster application architecture for the MVP v1.0 release. The architecture is designed as a modern full-stack application with a Flutter mobile frontend and a Spring Boot backend.

---

## 🏗️ System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                       FLUTTER APPLICATION                       │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │
│  │   Screens   │  │   Widgets   │  │       Services          │  │
│  │ (UI Layer)  │  │ (Reusable)  │  │ (Business Logic)        │  │
│  └─────────────┘  └─────────────┘  └─────────────────────────┘  │
│                              │                                   │
│                              ▼                                   │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │                    API Service Layer                        ││
│  │            (HTTP Client - Backend Integration)              ││
│  └─────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ REST API (HTTP/HTTPS)
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                     SPRING BOOT BACKEND                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │
│  │ Controllers │  │  Services   │  │     Repositories        │  │
│  │(REST API)   │──│(Business)   │──│   (Data Access)         │  │
│  └─────────────┘  └─────────────┘  └─────────────────────────┘  │
│                              │                                   │
│                              ▼                                   │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │                     External APIs                           ││
│  │              (Groq AI, Piper TTS)                           ││
│  └─────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ JPA/Hibernate
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                       POSTGRESQL DATABASE                        │
│                    (Persistent Storage)                          │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📁 Project Structure

### Backend (Spring Boot)
```
backend/
├── src/main/java/com/ingilizce/calismaapp/
│   ├── controller/          # REST API endpoints
│   │   ├── WordController.java
│   │   ├── SentenceController.java
│   │   ├── UserController.java
│   │   ├── UserProgressController.java
│   │   └── GroqController.java
│   ├── entity/              # JPA entities (Database models)
│   │   ├── User.java
│   │   ├── Word.java
│   │   ├── Sentence.java
│   │   ├── UserProgress.java
│   │   ├── SentencePractice.java
│   │   └── (Social entities - deferred)
│   ├── repository/          # Data access layer
│   │   ├── UserRepository.java
│   │   ├── WordRepository.java
│   │   └── SentenceRepository.java
│   ├── service/             # Business logic
│   │   ├── GroqService.java
│   │   ├── SRSService.java
│   │   └── UserDataService.java
│   └── dto/                 # Data transfer objects
├── src/main/resources/
│   └── application.properties
└── pom.xml
```

### Frontend (Flutter)
```
flutter_vocabmaster/
├── lib/
│   ├── main.dart            # App entry point
│   ├── screens/             # UI screens
│   │   ├── home_page.dart
│   │   ├── words_page.dart
│   │   ├── practice_page.dart
│   │   ├── review_page.dart
│   │   ├── stats_page.dart
│   │   └── profile_page.dart
│   ├── widgets/             # Reusable components
│   │   ├── bottom_nav.dart
│   │   ├── animated_background.dart
│   │   ├── modern_card.dart
│   │   └── navigation_menu_panel.dart
│   ├── services/            # Backend communication
│   │   ├── api_service.dart
│   │   ├── groq_service.dart
│   │   ├── user_data_service.dart
│   │   └── offline_sync_service.dart
│   └── models/              # Data models
│       ├── word.dart
│       └── sentence.dart
└── pubspec.yaml
```

---

## 🗄️ Database Schema

### Core Entities

#### 1. Users
| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | BIGINT | PK, AUTO_INCREMENT | Primary key |
| email | VARCHAR(255) | UNIQUE, NOT NULL | User email |
| password_hash | VARCHAR(255) | NOT NULL | Encrypted password |
| display_name | VARCHAR(255) | NOT NULL | Display name |
| user_tag | VARCHAR(10) | NOT NULL | Unique user tag (#12345) |
| subscription_end_date | TIMESTAMP | NULLABLE | Premium expiration |
| role | ENUM | NOT NULL | USER/ADMIN |
| created_at | TIMESTAMP | NOT NULL | Registration date |
| last_seen_at | TIMESTAMP | NULLABLE | Last activity |

#### 2. Words
| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | BIGINT | PK, AUTO_INCREMENT | Primary key |
| user_id | BIGINT | NOT NULL, INDEX | Owner reference |
| english_word | VARCHAR(255) | NOT NULL, INDEX | English vocabulary |
| turkish_meaning | VARCHAR(255) | | Turkish translation |
| learned_date | DATE | NOT NULL | When added |
| difficulty | VARCHAR(50) | | easy/medium/hard |
| notes | TEXT | | User notes |
| next_review_date | DATE | INDEX | SRS scheduling |
| review_count | INTEGER | | Times reviewed |
| ease_factor | DECIMAL | | SRS algorithm factor |
| last_review_date | DATE | | Last review date |

**Indexes:**
- `idx_word_user` on `user_id`
- `idx_word_english` on `english_word`
- `idx_word_user_srs` on `(user_id, next_review_date)`
- Unique constraint on `(user_id, english_word)`

#### 3. Sentences
| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | BIGINT | PK, AUTO_INCREMENT | Primary key |
| word_id | BIGINT | FK, NOT NULL | Parent word |
| sentence | TEXT | NOT NULL, INDEX | English sentence |
| translation | TEXT | | Turkish translation |
| difficulty | VARCHAR(50) | | Difficulty level |

**Indexes:**
- `idx_sentence_content` on `sentence`

#### 4. User Progress
| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | BIGINT | PK, AUTO_INCREMENT | Primary key |
| user_id | BIGINT | FK | User reference |
| total_xp | INTEGER | DEFAULT 0 | Experience points |
| level | INTEGER | DEFAULT 1 | Current level |
| current_streak | INTEGER | DEFAULT 0 | Active streak |
| longest_streak | INTEGER | DEFAULT 0 | Best streak |
| last_activity_date | DATE | | Last active |
| created_at | TIMESTAMP | | Creation time |
| updated_at | TIMESTAMP | | Last update |

#### 5. Sentence Practices
| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | BIGINT | PK, AUTO_INCREMENT | Primary key |
| user_id | BIGINT | NOT NULL | Owner |
| english_sentence | TEXT | NOT NULL | Practice sentence |
| turkish_translation | TEXT | | Translation |
| difficulty | ENUM | NOT NULL | EASY/MEDIUM/HARD |
| created_date | DATE | | Creation date |

---

## 🔌 API Endpoints

### Core APIs (Active in MVP)

#### Words API
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/words` | Get all words for user |
| GET | `/api/words/{id}` | Get word by ID |
| GET | `/api/words/today` | Get today's words |
| GET | `/api/words/date/{date}` | Get words by date |
| POST | `/api/words` | Create new word |
| PUT | `/api/words/{id}` | Update word |
| DELETE | `/api/words/{id}` | Delete word |

#### Sentences API
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/sentences` | Get all sentences |
| GET | `/api/sentences/{id}` | Get sentence by ID |
| POST | `/api/sentences` | Create sentence |
| DELETE | `/api/sentences/{id}` | Delete sentence |

#### User API
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/users/{id}` | Get user profile |
| PUT | `/api/users/{id}` | Update user |
| GET | `/api/users/{id}/progress` | Get user progress |
| POST | `/api/users/login` | User login |
| POST | `/api/users/register` | User registration |

#### AI API (via Groq)
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/groq/lookup` | Dictionary lookup |
| POST | `/api/groq/chat` | AI conversation |
| POST | `/api/groq/explain` | Explain word in context |

---

## ✅ MVP Features Status

### Active Features (v1.0)
- ✅ User Authentication (Email/Password)
- ✅ Word Management (CRUD)
- ✅ Sentence Management
- ✅ AI Dictionary (Groq Integration)
- ✅ Practice Modes (Reading/Writing/Translation)
- ✅ SRS (Spaced Repetition System)
- ✅ XP & Level System
- ✅ Statistics Dashboard
- ✅ User Profile
- ✅ Offline Support (Local SQLite sync)

### Disabled Features (Post-MVP)
- ❌ User Chat (Sohbet)
- ❌ Video Matching (Eşleşme)
- ❌ Social Feed
- ❌ Notifications
- ❌ Friend System
- ❌ Global Matchmaking

---

## 🔒 Security

### Current Implementation
- Password hashing (BCrypt)
- CORS configuration
- Environment variable for sensitive data (API keys)
- User-scoped data access (userId filtering)

### Recommendations for Production
1. Add JWT authentication
2. Implement rate limiting
3. Add HTTPS enforcement
4. Implement input validation/sanitization
5. Add audit logging

---

## 📊 Performance Considerations

### Database Optimization
- ✅ Indexes on frequently queried columns
- ✅ Composite indexes for common query patterns
- ✅ Unique constraints to prevent duplicates
- ⚠️ Consider adding pagination for large datasets

### API Optimization
- ⚠️ Add pagination support to list endpoints
- ⚠️ Consider caching for dictionary lookups
- ⚠️ Implement batch operations for bulk updates

---

## 🔜 Future Roadmap

### Phase 2: Social Features
1. Enable Chat functionality
2. Implement Friend system
3. Add Video Matching
4. Enable Social Feed

### Phase 3: Premium Features
1. Payment integration (Stripe/RevenueCat)
2. Advanced AI features
3. IELTS/TOEFL simulation

### Phase 4: Scale & Performance
1. CDN integration
2. Database read replicas
3. Microservices architecture (if needed)

---

## 📝 Notes

- All disabled features are preserved in codebase with `// MVP:` comments
- Backend services for social features are complete but not UI-connected
- Re-enabling features requires uncommenting marked code sections

---

*Generated: MVP v1.0 Release*
*Last Updated: January 2025*
