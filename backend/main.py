# ─────────────────────────────────────────────
#  TaskMaster – FastAPI Backend
#  Main application file: defines all REST API routes.
#  The Flutter frontend communicates with this server
#  over HTTP using JSON payloads.
# ─────────────────────────────────────────────

from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from typing import Optional
import asyncio

from database import SessionLocal, engine, Base
from models import TaskDB
from schemas import TaskCreate, TaskUpdate, TaskResponse

# Create all database tables on startup (if they don't exist yet)
Base.metadata.create_all(bind=engine)

app = FastAPI(title="TaskMaster API", version="1.0.0")

# Allow requests from any origin (needed for Flutter web on Chrome
# and Android emulator to reach this local server)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


# Dependency injected into every route that needs DB access.
# Ensures the session is always closed after the request finishes.
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


@app.get("/")
def root():
    """Health-check endpoint — confirms the server is running."""
    return {"message": "TaskMaster API is running!"}


@app.get("/tasks", response_model=list[TaskResponse])
def get_tasks(
    search: Optional[str] = None,   # Filter by title substring
    status: Optional[str] = None,   # Filter by status value
    db: Session = Depends(get_db)
):
    """
    Returns all tasks, optionally filtered by title search and/or status.
    Results are ordered by sort_order first, then creation time.
    """
    query = db.query(TaskDB)
    if search:
        # ilike = case-insensitive LIKE query in SQLAlchemy
        query = query.filter(TaskDB.title.ilike(f"%{search}%"))
    if status:
        query = query.filter(TaskDB.status == status)
    tasks = query.order_by(TaskDB.sort_order, TaskDB.created_at).all()
    return tasks


@app.get("/tasks/{task_id}", response_model=TaskResponse)
def get_task(task_id: int, db: Session = Depends(get_db)):
    """Returns a single task by its ID. Raises 404 if not found."""
    task = db.query(TaskDB).filter(TaskDB.id == task_id).first()
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    return task


@app.post("/tasks", response_model=TaskResponse)
async def create_task(task: TaskCreate, db: Session = Depends(get_db)):
    """
    Creates a new task and saves it to the database.
    Simulates a 2-second processing delay (assignment requirement).
    Uses async so the server remains responsive during the delay.
    """
    # Simulate network/processing delay without blocking the server
    await asyncio.sleep(2)

    # Validate that the blocking task actually exists
    if task.blocked_by_id:
        blocker = db.query(TaskDB).filter(TaskDB.id == task.blocked_by_id).first()
        if not blocker:
            raise HTTPException(status_code=400, detail="Blocking task not found")

    db_task = TaskDB(
        title=task.title,
        description=task.description,
        due_date=task.due_date,
        status=task.status,
        blocked_by_id=task.blocked_by_id,
        is_recurring=task.is_recurring,
        recurrence_type=task.recurrence_type,
    )
    db.add(db_task)
    db.commit()
    db.refresh(db_task)  # Reload from DB to get auto-generated fields (id, created_at)
    return db_task


@app.put("/tasks/{task_id}", response_model=TaskResponse)
async def update_task(task_id: int, task: TaskUpdate, db: Session = Depends(get_db)):
    """
    Updates an existing task.
    Simulates a 2-second processing delay (assignment requirement).
    Also handles recurring task logic: if a recurring task is marked Done,
    a new task is automatically created with the next due date.
    """
    await asyncio.sleep(2)

    db_task = db.query(TaskDB).filter(TaskDB.id == task_id).first()
    if not db_task:
        raise HTTPException(status_code=404, detail="Task not found")

    # Prevent a task from blocking itself
    if task.blocked_by_id and task.blocked_by_id == task_id:
        raise HTTPException(status_code=400, detail="A task cannot block itself")

    # Remember the old status before applying updates
    was_done = db_task.status == "Done"

    # Only update fields that were actually sent in the request (partial update)
    update_data = task.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(db_task, field, value)

    db.commit()
    db.refresh(db_task)

    # ── Recurring task logic ──────────────────────────────────────────
    # If the task just transitioned TO "Done" and is marked recurring,
    # automatically create the next occurrence with a pushed-forward due date.
    is_now_done = db_task.status == "Done"
    if not was_done and is_now_done and db_task.is_recurring and db_task.recurrence_type:
        from datetime import timedelta
        next_due = db_task.due_date
        if db_task.recurrence_type == "Daily":
            next_due = db_task.due_date + timedelta(days=1)
        elif db_task.recurrence_type == "Weekly":
            next_due = db_task.due_date + timedelta(weeks=1)

        # Create a fresh copy of the task with reset status and new due date
        new_task = TaskDB(
            title=db_task.title,
            description=db_task.description,
            due_date=next_due,
            status="To-Do",  # Always starts fresh
            blocked_by_id=db_task.blocked_by_id,
            is_recurring=db_task.is_recurring,
            recurrence_type=db_task.recurrence_type,
        )
        db.add(new_task)
        db.commit()

    return db_task


@app.delete("/tasks/{task_id}")
def delete_task(task_id: int, db: Session = Depends(get_db)):
    """
    Deletes a task by ID.
    Also clears the 'blocked_by' reference on any tasks that depended on
    the deleted task, so they don't point to a non-existent task.
    """
    db_task = db.query(TaskDB).filter(TaskDB.id == task_id).first()
    if not db_task:
        raise HTTPException(status_code=404, detail="Task not found")

    # Clean up foreign key references before deleting
    dependents = db.query(TaskDB).filter(TaskDB.blocked_by_id == task_id).all()
    for dep in dependents:
        dep.blocked_by_id = None

    db.delete(db_task)
    db.commit()
    return {"message": "Task deleted successfully"}


@app.get("/tasks/search/autocomplete")
def autocomplete(q: str, db: Session = Depends(get_db)):
    """
    Returns up to 5 task titles matching the query string.
    Used by the Flutter frontend's debounced search bar to show
    live suggestions as the user types.
    """
    if not q or len(q) < 1:
        return []
    results = (
        db.query(TaskDB.id, TaskDB.title)
        .filter(TaskDB.title.ilike(f"%{q}%"))
        .limit(5)
        .all()
    )
    return [{"id": r.id, "title": r.title} for r in results]