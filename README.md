# TaskMaster 📋

A full-stack Task Management app built with **Flutter** (frontend) and **FastAPI + SQLite** (backend).

---

## Track & Stretch Goal

- **Track A** — Full-Stack Builder (Flutter + Python FastAPI + SQLite)
- **Stretch Goal** — Debounced Autocomplete Search with highlighted matches
- **Bonus** — Recurring Tasks logic (auto-generates next occurrence when a recurring task is marked Done)

---

## Features

- ✅ Full CRUD — Create, Read, Update, Delete tasks
- ✅ Task fields: Title, Description, Due Date, Status, Blocked By
- ✅ Blocked tasks are visually greyed out with a lock icon
- ✅ Debounced search (300ms) with live autocomplete and highlighted matches
- ✅ Filter tasks by Status (All / To-Do / In Progress / Done)
- ✅ Draft saving — form content is preserved if you navigate away mid-typing
- ✅ 2-second simulated save delay with loading state; Save button disabled during save
- ✅ Swipe left to delete with confirmation dialog
- ✅ Overdue date highlighted in red
- ✅ Recurring tasks — marks Done → auto-creates next occurrence with pushed due date

---

## Tech Stack

| Layer     | Technology                      |
|-----------|---------------------------------|
| Frontend  | Flutter 3.x (Dart)              |
| Backend   | Python 3.11+ with FastAPI       |
| Database  | SQLite (via SQLAlchemy ORM)     |
| State     | Provider package                |
| Drafts    | SharedPreferences               |

---

## Prerequisites — Install These First (Windows)

### 1. Python 3.11+
1. Download from https://www.python.org/downloads/
2. **IMPORTANT**: During install, check ✅ **"Add Python to PATH"**
3. Verify: open CMD → `python --version`

### 2. Git
1. Download from https://git-scm.com/download/win
2. Install with all default settings

### 3. Flutter SDK
1. Download from https://docs.flutter.dev/get-started/install/windows
2. Extract to `C:\flutter` (do NOT use Program Files)
3. Add `C:\flutter\bin` to your system PATH:
   - Search **"Environment Variables"** in Windows search
   - System Variables → Path → Edit → New → type `C:\flutter\bin`
4. **Enable Developer Mode** (required on Windows 11):
   - Run in CMD: `start ms-settings:developers`
   - Toggle **Developer Mode** ON
5. Open a new CMD and run `flutter doctor`
6. Accept Android licenses if prompted: `flutter doctor --android-licenses`

> **Note:** Android Studio / emulator is NOT required. This app runs on Chrome.

---

## Project Structure

```
taskmaster/
├── backend/
│   ├── main.py          # FastAPI routes (all API endpoints)
│   ├── models.py        # SQLAlchemy ORM model (maps to SQLite table)
│   ├── schemas.py       # Pydantic schemas (request/response validation)
│   ├── database.py      # DB engine and session setup
│   └── requirements.txt
│
└── flutter_app/
    └── lib/
        ├── main.dart                      # App entry point
        ├── models/task.dart               # Task data class
        ├── providers/task_provider.dart   # State management (Provider)
        ├── screens/
        │   ├── task_list_screen.dart      # Main list screen
        │   └── task_form_screen.dart      # Create / Edit screen
        ├── widgets/
        │   ├── task_card.dart             # Individual task card UI
        │   └── search_bar.dart            # Debounced search + autocomplete
        └── services/
            ├── api_service.dart           # All HTTP calls to backend
            ├── draft_service.dart         # Draft persistence (SharedPreferences)
            └── app_theme.dart             # Colors, fonts, theme config
```

---

## Running the Project

### Clone the Repository
```bash
git clone https://github.com/coderchaubey/TaskManagementApp.git
cd TaskManagementApp
```

You will need two terminals open simultaneously — one for the backend, one for the frontend.

### Terminal 1 — Start the Backend

```bash
cd backend

python -m venv venv

# Mac/Linux:
source venv/bin/activate
# Windows:
venv\Scripts\activate

pip install -r requirements.txt

uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

You should see: `Uvicorn running on http://0.0.0.0:8000`

You can verify by opening http://localhost:8000/docs in your browser — Swagger UI shows all available endpoints interactively.

**Keep this terminal running.**

### Terminal 2 — Start the Flutter App

```bash
cd flutter_app

flutter pub get

flutter run -d chrome
```

The app will open in Chrome automatically. Make sure the backend is running first.

---

## API Endpoints

| Method | Endpoint                        | Description                         |
|--------|---------------------------------|-------------------------------------|
| GET    | `/tasks`                        | List tasks (supports search/filter) |
| GET    | `/tasks/{id}`                   | Get single task                     |
| POST   | `/tasks`                        | Create task (2s delay)              |
| PUT    | `/tasks/{id}`                   | Update task (2s delay)              |
| DELETE | `/tasks/{id}`                   | Delete task                         |
| GET    | `/tasks/search/autocomplete?q=` | Autocomplete suggestions            |

---

## AI Usage Report

### Tools Used
- **Claude (Anthropic)** — Primary code generation for backend and frontend

### Most Helpful Prompts
- *"Build a FastAPI backend with SQLAlchemy and Flutter for a task management app"* — Generated the full backend architecture cleanly.
- *"Build a Flutter debounced search bar with an overlay autocomplete dropdown that highlights matching text using the best method possible in a time bound environment"*

### When AI Got It Wrong
1. `flutter pub get` failed with a symlink error until Developer Mode was enabled in Windows Settings.

---

## Key Technical Decisions

**Why `asyncio.sleep(2)` instead of `time.sleep(2)`?**
FastAPI is async-native. `await asyncio.sleep(2)` suspends only the current request coroutine — the server event loop keeps running and handles other requests. `time.sleep(2)` would block the entire thread.

**Why SQLite over PostgreSQL?**
SQLite requires zero infrastructure — the database is a single file created automatically on first run, making setup trivial for anyone cloning the repo.
