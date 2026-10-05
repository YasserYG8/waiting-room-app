# Local Waiting Room App

An interactive Flutter application simulating a digital waiting room queue for healthcare clinics, service desks, or administrative offices. Built progressively across Workshop 1 and Workshop 2 following Test-Driven Development (TDD) principles and separation of concerns.

---

## Features

* **Queue Management**:
  * Client registration with name input validation and submission button.
  * Real-time counter displaying total clients currently in queue (`Clients in Queue: X`).
  * Scrollable list view (`ListView.builder`) rendering queued clients inside discrete cards.
  * Immediate client removal functionality via dedicated delete action buttons.
* **Component Architecture**:
  * Clear architectural separation between Business Logic (`WaitingRoomManager`) and Presentation Layer (`WaitingRoomScreen`).
  * Real-time clock widget (`WaitingRoomTimestamp`) backed by a periodic timer with lifecycle resource disposal.
* **Automated Testing and Continuous Integration**:
  * Unit tests validating queue operations independently in pure Dart.
  * Widget tests verifying UI rendering and simulated user actions (entering text, tapping buttons, asserting state changes).
  * GitHub Actions CI pipeline executing automated testing and static analysis on pushes and pull requests.

---

## Project Structure

```text
waiting_room_app/
├── .github/
│   └── workflows/
│       └── ci.yml                     # GitHub Actions CI configuration
├── lib/
│   ├── main.dart                      # Application entry point and WaitingRoomScreen UI
│   ├── waiting_room_manager.dart      # Core business logic (Pure Dart queue manager)
│   ├── waiting_room_card.dart         # Waiting room card presentation component
│   └── waiting_room_timestamp.dart    # Live timestamp widget with timer lifecycle
├── test/
│   ├── waiting_room_manager_test.dart # Unit tests for WaitingRoomManager
│   ├── waiting_room_widget_test.dart  # Widget tests for queue interactions (Add/Remove)
│   └── waiting_room_card_test.dart    # Widget tests for WaitingRoomCard
├── pubspec.yaml                       # Package dependencies and project metadata
└── README.md                          # Project documentation
```

---

## Architecture and Key Concepts

### 1. Separation of Concerns
* **`WaitingRoomManager` (`lib/waiting_room_manager.dart`)**:
  * Pure Dart class responsible for state mutation and queue management.
  * Encapsulates the internal `_clients` list behind an unmodifiable getter `clients`.
  * Exposes explicit methods: `addClient(String name)` and `removeClient(String name)`.
  * Independent of the Flutter framework, enabling fast, isolated unit testing without UI dependencies.

* **`WaitingRoomScreen` (`lib/main.dart`)**:
  * A `StatefulWidget` managing presentation state.
  * Utilizes a `TextEditingController` for reading and resetting input values.
  * Employs `ListView.builder` for scalable, on-demand list item rendering.

### 2. State Management with `setState()`
When clients are added or removed:
1. User events trigger actions on `WaitingRoomManager`.
2. Encapsulating state mutations within `setState(() { ... })` notifies the Flutter framework that the widget's internal state has updated.
3. The framework schedules a re-execution of the `build()` method, reflecting changes across the counter and list view.

---

## Test-Driven Development (TDD)

Application features were implemented following the standard TDD cycle:

1. **Red**: Define an automated unit or widget test asserting the expected behavior prior to implementation, verifying test failure.
2. **Green**: Implement the minimal required logic to satisfy the test specifications.
3. **Refactor**: Clean up and optimize the implementation while maintaining full test coverage.

### Test Suite Overview

* **Unit Tests (`test/waiting_room_manager_test.dart`)**:
  * `should add a client to the waiting list`: Verifies that adding a client increments the queue length and preserves ordering.
  * `should remove a client from the waiting list`: Verifies that removing a client correctly updates list elements.

* **Widget Tests (`test/waiting_room_widget_test.dart`)**:
  * `should add a new client to the list on button tap`: Simulates user input in the `TextField`, triggers the `ElevatedButton`, pumps the frame, and verifies the rendered text and updated counter.
  * `should remove a client from the list when the delete button is tapped`: Simulates tapping the delete icon and asserts removal from the widget tree.

---

## Getting Started

### Prerequisites
* Flutter SDK (version 3.19.0 or higher)
* Dart SDK (version 3.13.0 or higher)
* Target platform: Chrome (Web), Windows Desktop, or an Android/iOS emulator

### Setup and Execution

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
   flutter run
   ```

---

## CI/CD Pipeline

The project includes continuous integration via GitHub Actions defined in `.github/workflows/ci.yml`:
* **Triggers**: Executed on pull requests and pushes targeting the `main` branch.
* **Pipeline Jobs**:
  1. Source checkout.
  2. Flutter SDK setup.
  3. Dependency resolution (`flutter pub get`).
  4. Test suite execution (`flutter test`).
  5. Static code analysis (`flutter analyze`).
