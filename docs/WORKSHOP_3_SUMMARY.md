# Workshop 3 & Session Summary: Flutter Provider, TDD, and Queue Management

This document summarizes the complete work, explanations, code changes, and test executions completed during this session. It serves as a comprehensive recap and study guide for **Workshop 3 (TP3)**.

---

## Table of Contents
1. [Overview & Session Objectives](#1-overview--session-objectives)
2. [Documentation Analyzed](#2-documentation-analyzed)
3. [The Core Architectural Shift: setState() vs. Provider](#3-the-core-architectural-shift-setstate-vs-provider)
4. [Step-by-Step Implementation Chronology](#4-step-by-step-implementation-chronology)
5. [Core Logic Deep-Dive](#5-core-logic-deep-dive)
6. [Test Suite Verification (TDD)](#6-test-suite-verification-tdd)
7. [Git History & Commits](#7-git-history--commits)
8. [Oral Defense / Examination Cheat Sheet](#8-oral-defense--examination-cheat-sheet)

---

## 1. Overview & Session Objectives

The objective was to upgrade the **Local Waiting Room App** from **Workshop 2** to **Workshop 3**:
* Transition state management from local `setState()` to the official **`provider` package**.
* Add a new **Next Client** feature that serves the client at the front of the queue (First-In, First-Out / FIFO).
* Implement all features strictly following **Test-Driven Development (TDD)** (Red $\rightarrow$ Green $\rightarrow$ Refactor).
* Verify zero static analysis issues and pass all automated unit and widget tests.

---

## 2. Documentation Analyzed

During the session, three key documents from the `docs/` folder were reviewed and explained:

### A. `docs/PROJECT_EXPLANATION.md`
* Explained the foundations of the app: a waiting queue for a clinic or reception desk where clients can be added, viewed in a list, and deleted.
* Established the principle of **Separation of Concerns**: separating the pure Dart queue manager from the Flutter UI.
* Covered the basic TDD cycle and continuous integration (CI) pipeline via GitHub Actions.

### B. `docs/Flutter Provider — Step-by-Step Guide.pdf`
* A guide explaining reactive state management with the `provider` package.
* **Key Concept: The Global Messenger**:
  * `ChangeNotifier`: The "Brain" holding data and business rules.
  * `notifyListeners()`: The "Megaphone" shouting to the app that data has changed.
  * `ChangeNotifierProvider`: Dependency injection tool that exposes state to widgets down the tree.
  * `context.watch<T>()`: "The Ears" — subscribes to state changes and rebuilds the UI.
  * `context.read<T>()`: "The Hand" — reads the provider once to trigger actions (buttons) without rebuilding.

### C. `docs/Workshop 3 — Provider & Scalable State Management.pdf`
* The official specification for Workshop 3.
* Motivated moving beyond `setState()` to prevent **prop-drilling** and **unnecessary widget rebuilds**.
* Defined the tasks:
  1. Add `provider` dependency.
  2. Implement `QueueProvider` with `nextClient()` using TDD.
  3. Refactor `main.dart` into a `StatelessWidget`.
  4. Add an `AppBar` button (`Icons.skip_next`) for "Next Client".
  5. Validate via unit and widget tests.

---

## 3. The Core Architectural Shift: setState() vs. Provider

| Dimension | Workshop 2 (`setState`) | Workshop 3 (`Provider`) |
| :--- | :--- | :--- |
| **State Storage** | Inside `_WaitingRoomScreenState` | Centralized in `QueueProvider` |
| **Widget Type** | Heavy `StatefulWidget` | Lightweight `StatelessWidget` |
| **Notification** | `setState(() { ... })` triggers entire widget rebuild | `notifyListeners()` triggers granular listener rebuilds |
| **Data Sharing** | Must pass manager down constructors (prop-drilling) | Accessible anywhere using `context.watch()` or `context.read()` |
| **Testing** | Difficult to isolate UI from state updates | Easy to mock or inject `QueueProvider` in tests |

---

## 4. Step-by-Step Implementation Chronology

### Step 1: Dependency Setup
* Added `provider: ^6.1.2` to `pubspec.yaml` under `dependencies:`.
* Executed `flutter pub get` (exit code `0`, dependencies resolved cleanly).

### Step 2: TDD Unit Testing for Business Logic
1. **Red**: Wrote a unit test in `test/waiting_room_manager_test.dart` for the new `nextClient()` method before writing any code.
2. **Green**: Created `lib/queue_provider.dart` extending `ChangeNotifier` with `addClient()`, `removeClient()`, and `nextClient()`, all ending with `notifyListeners()`.
3. Removed deprecated `lib/waiting_room_manager.dart`.
4. Verified all 3 unit tests passed in `< 1s`.

### Step 3: TDD Widget Testing for UI Interaction
1. **Red**: Added a widget test in `test/waiting_room_widget_test.dart` testing the `nextClientButton` action.
2. Wrapped widget tests with `ChangeNotifierProvider(create: (_) => QueueProvider(), child: WaitingRoomApp())`.
3. Verified the test failed before UI implementation.

### Step 4: UI Implementation & Refactoring
1. Wrapped `WaitingRoomApp` inside `ChangeNotifierProvider` in `lib/main.dart`'s `main()` function.
2. Refactored `WaitingRoomScreen` from `StatefulWidget` to `StatelessWidget`.
3. Connected data reading using `context.watch<QueueProvider>()`.
4. Added the "Next Client" action button in the `AppBar` using `context.read<QueueProvider>().nextClient()`.
5. Connected "Add" and "Delete" button actions using `context.read<QueueProvider>()`.

### Step 5: Verification & Launch
1. Ran `flutter test` $\rightarrow$ **7/7 tests passed**.
2. Ran `flutter analyze` $\rightarrow$ **0 issues found**.
3. Launched the app live in **Google Chrome** via `flutter run -d chrome`.

---

## 5. Core Logic Deep-Dive

### 1. `lib/queue_provider.dart` (The Business Logic)
```dart
import 'package:flutter/foundation.dart';

class QueueProvider extends ChangeNotifier {
  // Private encapsulated state
  final List<String> _clients = [];

  // Public read-only getter
  List<String> get clients => _clients;

  // Add client to back of queue
  void addClient(String name) {
    _clients.add(name);
    notifyListeners();
  }

  // Remove specific client
  void removeClient(String name) {
    _clients.remove(name);
    notifyListeners();
  }

  // Workshop 3 FIFO feature: Serve client at index 0
  void nextClient() {
    if (_clients.isNotEmpty) {
      _clients.removeAt(0);
      notifyListeners();
    }
  }
}
```

### 2. `lib/main.dart` (The User Interface)
```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:waiting_room_app/queue_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => QueueProvider(),
      child: const WaitingRoomApp(),
    ),
  );
}

class WaitingRoomApp extends StatelessWidget {
  const WaitingRoomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: WaitingRoomScreen(),
    );
  }
}

class WaitingRoomScreen extends StatelessWidget {
  const WaitingRoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final queueProvider = context.watch<QueueProvider>();
    final TextEditingController controller = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Waiting Room'),
        actions: [
          IconButton(
            key: const Key('nextClientButton'),
            icon: const Icon(Icons.skip_next),
            tooltip: 'Next Client',
            onPressed: () {
              context.read<QueueProvider>().nextClient();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(labelText: 'Client Name'),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (controller.text.isNotEmpty) {
                      context.read<QueueProvider>().addClient(controller.text);
                      controller.clear();
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Clients in Queue: ${queueProvider.clients.length}'),
            Expanded(
              child: ListView.builder(
                itemCount: queueProvider.clients.length,
                itemBuilder: (context, index) {
                  final clientName = queueProvider.clients[index];
                  return Card(
                    child: ListTile(
                      title: Text(clientName),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          context.read<QueueProvider>().removeClient(clientName);
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 6. Test Suite Verification (TDD)

All **7 tests** in the test suite pass:

| Test File | Test Case Name | Category | Purpose | Status |
| :--- | :--- | :--- | :--- | :--- |
| `waiting_room_card_test.dart` | `WaitingRoomCard displays the name correctly` | Component Test | Verifies client card text rendering | ✅ Passed |
| `waiting_room_manager_test.dart` | `should add a client to the waiting list` | Unit Test | Verifies adding client to internal list | ✅ Passed |
| `waiting_room_manager_test.dart` | `should remove a client from the waiting list` | Unit Test | Verifies specific client removal | ✅ Passed |
| `waiting_room_manager_test.dart` | `should remove the first client when nextClient is called` | Unit Test | Verifies FIFO removal at index 0 | ✅ Passed |
| `waiting_room_widget_test.dart` | `should add a new client to the list on button tap` | Widget Test | Simulates text entry and Add button tap | ✅ Passed |
| `waiting_room_widget_test.dart` | `should remove a client from the list when the delete button is tapped` | Widget Test | Simulates trash icon tap | ✅ Passed |
| `waiting_room_widget_test.dart` | `should remove the first client from the list when "Next Client" is tapped` | Widget Test | Simulates Next Client AppBar icon tap | ✅ Passed |

---

## 7. Git History & Commits

The project's git repository is clean and up-to-date with two new commits:

1. **`1680f86`** — `feat : project TP3 - Provider & scalable state management with TDD`
   * Added `lib/queue_provider.dart`
   * Refactored `lib/main.dart`
   * Updated `pubspec.yaml` with `provider: ^6.1.2`
   * Updated unit and widget tests
   * Removed deprecated `lib/waiting_room_manager.dart`
2. **`6a024e3`** — `docs : update README.md for Workshop 3`
   * Comprehensive updates to `README.md` reflecting Workshop 3 architecture, testing commands, and features.

---

## 8. Oral Defense / Examination Cheat Sheet

Here are answers to likely questions in an oral exam or project review:

### Q1: Why did you migrate from `setState()` to Provider in Workshop 3?
> **Answer**: `setState()` causes two major problems as apps grow:
> 1. **Prop-drilling**: You must pass the state manager through every widget constructor.
> 2. **Inefficient rebuilds**: `setState()` rebuilds the entire widget and all its children.
> Provider centralizes state, allows any widget to access data directly without passing props, and rebuilds only the widgets subscribed via `context.watch()`.

### Q2: What is the difference between `context.watch()` and `context.read()`?
> **Answer**:
> * `context.watch<T>()` subscribes to the provider and **rebuilds the widget** whenever `notifyListeners()` is called. It is used where data is displayed (e.g. queue counter and list).
> * `context.read<T>()` retrieves the provider instance **once without listening**. It is used inside button callbacks (`onPressed`) to trigger methods without triggering unnecessary rebuilds.

### Q3: Why could `WaitingRoomScreen` become a `StatelessWidget`?
> **Answer**: In Workshop 2, `WaitingRoomScreen` was a `StatefulWidget` because it needed `setState()` to redraw. In Workshop 3, the state is held externally by `QueueProvider`. The `Provider` package manages rebuilding the UI when `notifyListeners()` is called, eliminating the need for local widget state.

### Q4: How does the "Next Client" button work under the hood?
> **Answer**: Tapping the button calls `context.read<QueueProvider>().nextClient()`. Inside `QueueProvider`, `_clients.removeAt(0)` removes the first element (FIFO queue behavior), followed by `notifyListeners()`, which causes the screen to redraw without the served client.
