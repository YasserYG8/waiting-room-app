# Local Waiting Room App

An interactive Flutter application simulating a digital waiting room queue for healthcare clinics, service desks, or administrative offices. Built progressively across **Workshop 1**, **Workshop 2**, and **Workshop 3**, evolving from a static UI into an interactive queue with `setState()`, and finally into a scalable, reactive architecture using the **Provider** package and **Test-Driven Development (TDD)**.

---

## Features

* **Queue Management**:
  * Client registration with name input validation and submission button.
  * Real-time counter displaying total clients currently in queue (`Clients in Queue: X`).
  * Scrollable list view (`ListView.builder`) rendering queued clients inside cards.
  * Individual client removal functionality via dedicated delete action buttons.
  * **Next Client Action (Workshop 3)**: An `AppBar` skip action button (`Icons.skip_next`) to serve and remove the first person in the queue (FIFO: First-In, First-Out).
* **Scalable State Management (Provider)**:
  * Centralized reactive state using `QueueProvider` extending `ChangeNotifier`.
  * Dependency injection at the root of the widget tree via `ChangeNotifierProvider`.
  * Clean UI separation: `WaitingRoomScreen` implemented as a lightweight `StatelessWidget`.
  * Fine-grained widget rebuilds using `context.watch<QueueProvider>()` for state display and `context.read<QueueProvider>()` for action callbacks.
* **Component Architecture**:
  * Real-time clock widget (`WaitingRoomTimestamp`) backed by a periodic timer with lifecycle resource disposal.
  * Reusable client card widget (`WaitingRoomCard`).
* **Automated Testing and Continuous Integration**:
  * Comprehensive unit tests validating queue operations (`addClient`, `removeClient`, `nextClient`).
  * Widget tests simulating user actions (typing, tapping buttons, asserting UI transitions) with headless Flutter rendering (`WidgetTester`).
  * Automated GitHub Actions CI pipeline executing tests and static analysis on every push and pull request.

---

## Project Structure

```text
waiting_room_app/
├── .github/
│   └── workflows/
│       └── ci.yml                     # GitHub Actions CI configuration
├── lib/
│   ├── main.dart                      # Application entry point and StatelessWidget UI
│   ├── queue_provider.dart            # Core business logic & state (ChangeNotifier)
│   ├── waiting_room_card.dart         # Waiting room card presentation component
│   └── waiting_room_timestamp.dart    # Live timestamp widget with timer lifecycle
├── test/
│   ├── waiting_room_manager_test.dart # Unit tests for QueueProvider
│   ├── waiting_room_widget_test.dart  # Widget tests for queue interactions (Add, Delete, Next)
│   └── waiting_room_card_test.dart    # Widget tests for WaitingRoomCard
├── pubspec.yaml                       # Package dependencies (Provider, Cupertino Icons)
└── README.md                          # Project documentation
```

---

## Architecture & State Management

### 1. Business Logic: `QueueProvider` (`lib/queue_provider.dart`)
* Inherits from `ChangeNotifier` to hold queue state and notify listeners on changes.
* Encapsulates the internal `_clients` list with a read-only getter `clients`.
* Exposes explicit queue management operations:
  * `addClient(String name)`: Appends a client to the queue and triggers `notifyListeners()`.
  * `removeClient(String name)`: Removes a specific client and triggers `notifyListeners()`.
  * `nextClient()`: Pops the first client from index 0 (serving the next person) and triggers `notifyListeners()`.

### 2. Dependency Injection & UI: `main.dart`
* **Root Injection**: `ChangeNotifierProvider(create: (_) => QueueProvider(), child: const WaitingRoomApp())` makes the queue accessible across the entire widget hierarchy without prop-drilling.
* **`WaitingRoomScreen` (`StatelessWidget`)**:
  * **Listening to State**: Uses `context.watch<QueueProvider>()` to subscribe to queue changes. Only rebuilds when `notifyListeners()` is triggered.
  * **Dispatching Actions**: Uses `context.read<QueueProvider>()` inside event handlers (`onPressed`) to trigger methods without unnecessary widget rebuilds.

| Method | Role | Example Usage |
| :--- | :--- | :--- |
| `context.watch<T>()` | Subscribes to updates & rebuilds UI | `Text('Clients in Queue: ${queueProvider.clients.length}')` |
| `context.read<T>()` | Reads instance once for actions | `context.read<QueueProvider>().nextClient()` |

---

## Test-Driven Development (TDD)

Every feature follows the strict **Red $\rightarrow$ Green $\rightarrow$ Refactor** cycle:

1. **Red**: Define an automated unit or widget test asserting the expected behavior prior to implementation, verifying that it fails.
2. **Green**: Implement the minimal required logic to satisfy the test specifications.
3. **Refactor**: Clean up and optimize the implementation while maintaining full test coverage.

### Test Suite Overview (7/7 Passing)

* **Unit Tests (`test/waiting_room_manager_test.dart`)**:
  * `should add a client to the waiting list`: Verifies client registration and list preservation.
  * `should remove a client from the waiting list`: Verifies specific client removal by name.
  * `should remove the first client when nextClient is called`: Verifies that `nextClient()` pops the first client from index 0.

* **Widget Tests (`test/waiting_room_widget_test.dart`)**:
  * `should add a new client to the list on button tap`: Enters name in `TextField`, taps `ElevatedButton`, pumps frames, and asserts that the client card and updated counter appear.
  * `should remove a client from the list when the delete button is tapped`: Taps the delete icon on a card and asserts immediate removal.
  * `should remove the first client from the list when "Next Client" is tapped`: Tests that tapping the `nextClientButton` in the `AppBar` removes the front client while preserving subsequent clients.

* **Component Tests (`test/waiting_room_card_test.dart`)**:
  * `WaitingRoomCard displays the name correctly`: Asserts that `WaitingRoomCard` properly renders the assigned client string.

---

## Getting Started

### Prerequisites
* Flutter SDK (version 3.19.0 or higher)
* Dart SDK (version 3.13.0 or higher)
* Target platform: Chrome (Web), Windows Desktop, or an Android/iOS emulator

### Setup & Execution

1. **Clone the repository**:
   ```bash
   git clone https://github.com/YasserYG8/waiting-room-app.git
   cd waiting-room-app
   ```

2. **Retrieve dependencies**:
   ```bash
   flutter pub get
   ```

3. **Execute test suite**:
   ```bash
   flutter test
   ```

4. **Run static analysis**:
   ```bash
   flutter analyze
   ```

5. **Launch the application**:
   ```bash
   flutter run -d chrome     # Run in Chrome Web
   flutter run -d windows    # Run as Windows Desktop app
   ```

---

## CI/CD Pipeline

Continuous integration is automated via GitHub Actions in `.github/workflows/ci.yml`:
* **Triggers**: Executed on pull requests and pushes targeting the `main` branch.
* **Pipeline Jobs**:
  1. Source checkout.
  2. Flutter SDK environment setup.
  3. Dependency resolution (`flutter pub get`).
  4. Test suite execution (`flutter test`).
  5. Static code quality analysis (`flutter analyze`).
