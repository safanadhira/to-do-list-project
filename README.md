# Safa's To-Do List

A sleek, intuitive, and modern mobile task management application built using Flutter and Dart. Designed with **Material Design 3**, this app delivers a seamless personal productivity experience, allowing users to organize daily workflows, track milestones with real-time countdowns, and dynamically prioritize tasks using interactive drag-and-drop mechanics.

---

## Features

- **Dynamic Task Management (CRUD):** Easily create, view, update, and delete tasks. Each task supports a mandatory title, detailed multi-line descriptions, customized categorization, and explicit deadline schedules.
- **Interactive Drag-and-Drop Reordering:** Prioritize tasks on the fly. Powered by `ReorderableListView`, users can press and slide task cards to re-arrange their daily focus instantly.
- **Real-Time Countdown & Overdue Tracker:** Never miss a sub-task. An internal async timer recalibrates remaining durations every 60 seconds, dynamically color-coding overdue tasks in bold crimson text.
- **Multi-Dimensional Filtering:** Sift through dense workflows instantly using concurrent filters. Users can toggle completion states (*All, Completed, Incomplete*) while narrowing down specific subjects using an adaptive dropdown menu.
- **Adaptive Theme Engine:** Personalize your visual workspace. Features a quick-toggle canvas supporting seamless transitions between high-contrast Light and Dark mode variations.
- **Persistent Local Storage:** Powered by `SharedPreferences`, your task matrices, customized category lists, and user configurations are committed to local disk storage to ensure continuous data retention across application cycles.

---

## Architecture & Technical Design

The codebase utilizes a modular **Stateful Widget Component Architecture (Monolithic Widget State)** leveraging Flutter’s native ephemeral state engine. Responsibilities are distributed across clean conceptual layers within `main.dart`:

1. **Data Model Layer (`TaskItem`):** An independent, encapsulated data class managing task entities. It includes self-contained serialization and deserialization routines (`toJson` and `fromJson`) to translate deep object graphs into persistent string formats.
2. **Controller / State Logic Layer (`_HomeState`):** Acts as the central nervous system of the application. It orchestrates asynchronous local I/O, multi-conditional data filters (`_filteredTasks`), array index transformation algorithms (`_reorderVisibleTasks`), and handles instantaneous UI updates via reactive state triggers.
3. **View Layer (`Home` & `TaskCard`):** Modular widget layers dedicated exclusively to structural rendering. The UI components remain decoupled from hardcoded business operations by shifting interface events back to the controller layer using event-driven callbacks (`onCompletionChanged`, `onEdit`, `onDelete`).

### System Workflow
<img width="3147" height="1685" alt="Blank diagram" src="https://github.com/user-attachments/assets/f34cdc81-0815-49c7-88d9-188298f77774" />

---

## Tech Stack & Dependencies

- **Framework:** [Flutter SDK](https://flutter.dev) (Cross-Platform Mobile Engine)
- **Language:** [Dart](https://dart.dev) (Optimized for fast client-side applications)
- **State & Persistence:** `shared_preferences` (Native platform asynchronous key-value disk storage)
- **Data Parsing:** `dart:convert` (`jsonEncode` / `jsonDecode` structural translation matrix)
- **Asynchronous Scheduling:** `dart:async` (`Timer.periodic` background loop execution)
- **Design System:** Material Design 3 (Adaptive brown seed palette)
