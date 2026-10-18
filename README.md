# Real-Time Waiting Room App

A distributed, real-time Flutter application simulating a digital waiting room queue for healthcare clinics, service desks, or administrative offices. Built progressively across **Workshops 1 through 4**, evolving from a static UI into an interactive queue with `setState()`, scaling with **Provider**, and culminating in a cloud-backed, multi-device synchronized system powered by **Supabase** (PostgreSQL, Row-Level Security, and WebSockets).

---

## Features

* **Real-Time Cloud Synchronization (Workshop 4)**:
  * Backend-as-a-Service integration using the official `supabase_flutter` SDK.
  * Real-time WebSocket replication via PostgreSQL publication (`supabase_realtime`): additions and removals sync instantly across all connected screens and devices with zero refresh required.
  * Anonymous authentication handling via `signInAnonymously()`.
  * Secure credential management using `flutter_dotenv` and `.env` files kept out of version control.
* **Queue Management**:
  * Client registration with input validation, keyboard submission, and automated field clearing.
  * Real-time status banner displaying total clients currently waiting (`Clients in Queue: X`) alongside a live sync status indicator.
  * Responsive list view (`ListView.builder`) rendering queued clients in cards with initials avatars and formatted arrival timestamps (`HH:mm:ss`).
  * Individual client removal via dedicated delete actions.
  * FIFO queue progression via the primary "Next Client" action button.
* **Architecture & State Management**:
  * Centralized reactive state using `QueueProvider` extending `ChangeNotifier`.
  * Strongly typed domain model (`Client`) with JSON serialization (`fromMap` and `toMap`).
  * Dependency injection at the root of the widget tree via `ChangeNotifierProvider`.
  * Proper resource cleanup: cancels real-time database channel subscriptions upon provider disposal.
* **Quality Assurance & CI/CD**:
  * Unit tests validating `QueueProvider` in isolation with mock/fake Supabase clients.
  * Component and widget tests verifying user interactions and rendering.
  * Automated GitHub Actions CI pipeline executing tests and static analysis on pushes and pull requests.

---

## Project Structure

```text
waiting_room_app/
├── .github/
│   └── workflows/
│       └── ci.yml                     # GitHub Actions CI automated pipeline
├── lib/
│   ├── main.dart                      # App entry point, Supabase initialization, and UI
│   ├── models/
│   │   └── client.dart                # Strongly typed Client domain model
│   ├── queue_provider.dart            # Supabase real-time state management (ChangeNotifier)
│   ├── waiting_room_card.dart         # Waiting room card presentation component
│   └── waiting_room_timestamp.dart    # Live timestamp widget with timer lifecycle
├── test/
│   ├── queue_provider_test.dart       # Unit tests for Supabase QueueProvider operations
│   ├── waiting_room_manager_test.dart # Unit tests for local queue logic
│   ├── waiting_room_widget_test.dart  # Widget tests for queue interactions
│   └── waiting_room_card_test.dart    # Widget tests for client card component
├── .env.example                       # Template for Supabase environment variables
├── pubspec.yaml                       # Package dependencies and asset configurations
└── README.md                          # Project documentation
```

---

## Architecture and Technical Design

### 1. Backend Architecture (Supabase PostgreSQL & RLS)

The backend runs on Supabase without custom server-side boilerplate:

* **Table Schema (`clients`)**:
  * `id`: `uuid` (Primary Key, default: `gen_random_uuid()`)
  * `name`: `text` (Client's full name)
  * `created_at`: `timestamp with time zone` (default: `now()`)

* **Row-Level Security (RLS) Policies**:
  To allow public client registration while keeping database operations secure, explicit policies are applied:
  * **SELECT**: Allows reading the queue for all anonymous and authenticated users.
  * **INSERT**: Allows adding clients with validated names.
  * **DELETE**: Allows dequeuing and removing clients.
  * **Publication**: `ALTER PUBLICATION supabase_realtime ADD TABLE clients;` activates WebSocket change broadcasts.

### 2. Client Domain Model (`lib/models/client.dart`)

```dart
class Client {
  final String id;
  final String name;
  final DateTime createdAt;

  Client({required this.id, required this.name, required this.createdAt});

  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      id: map['id'] as String,
      name: map['name'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
```

### 3. Real-Time State Management (`lib/queue_provider.dart`)

`QueueProvider` handles data querying, WebSocket listening, and state broadcasting:

* **Initial Fetch**: Queries the `clients` table ordered by `created_at` on launch.
* **Realtime Listener**: Listens to PostgreSQL `INSERT` and `DELETE` events over WebSockets via `onPostgresChanges`:
  * When a new client is added on any device, it is deserialized, inserted into `_clients`, sorted by arrival time, and triggers `notifyListeners()`.
  * When a client is deleted, it is removed by `id` from the local list and triggers `notifyListeners()`.
* **Testing Constructor**: Exposes `QueueProvider.forTesting(this._supabase)` allowing dependency injection of mock clients for isolated unit testing.
* **Lifecycle Cleanup**: Calls `_supabase.removeChannel(_channel!)` in `dispose()` to prevent network and memory leaks.

---

## Test-Driven Development (TDD) & Quality Assurance

The codebase incorporates unit, widget, and integration testing:

### 1. Automated Unit Tests (`test/queue_provider_test.dart`)
Tests `QueueProvider` operations in isolation using custom test fakes for `SupabaseClient` and `SupabaseQueryBuilder`:
* `addClient calls insert with client name`: Verifies that adding a client delegates to the database with the proper payload.
* `addClient does not call insert when name is empty`: Asserts that empty/whitespace inputs are rejected prior to querying the database.
* `removeClient calls delete matching id`: Verifies that deleting a client queries by exact UUID.
* `nextClient does not call delete when queue is empty`: Ensures safe execution when attempting to dequeue from an empty list.

### 2. Manual Real-Time Integration Test
* **Setup**: Launch the application on two separate devices or two Google Chrome tabs.
* **Device A**: Enter a client name (e.g., "John Doe") and click "Add".
* **Device B**: Verify that "John Doe" appears in the queue immediately without manual page refresh.
* **Device B**: Click "Next Client".
* **Device A**: Verify that "John Doe" is dequeued and removed from both screens simultaneously.

---

## Getting Started

### Prerequisites
* Flutter SDK (version 3.19.0 or higher)
* Dart SDK (version 3.13.0 or higher)
* Supabase account and project

### Environment Configuration

Create a `.env` file in the project root:

```env
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-anon-public-key
```

Ensure `.env` is listed under `assets` in `pubspec.yaml` and is present in `.gitignore`.

### Installation & Execution

1. **Clone the repository**:
   ```bash
   git clone https://github.com/YasserYG8/waiting-room-app.git
   cd waiting-room-app
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run unit and widget tests**:
   ```bash
   flutter test test/queue_provider_test.dart
   ```

4. **Execute static code analysis**:
   ```bash
   flutter analyze
   ```

5. **Launch the application**:
   ```bash
   flutter run -d chrome     # Run in Google Chrome
   flutter run -d windows    # Run as Windows desktop application
   ```

---

## CI/CD Pipeline

Continuous integration is automated via GitHub Actions in `.github/workflows/ci.yml`:
* **Triggers**: Automated execution on pull requests and pushes targeting the `main` branch.
* **Pipeline Steps**:
  1. Source checkout.
  2. Flutter SDK setup.
  3. Dependency resolution (`flutter pub get`).
  4. Test suite execution (`flutter test`).
  5. Static code analysis (`flutter analyze`).
