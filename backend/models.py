# ─────────────────────────────────────────────
#  TaskMaster – Database Models
#  Defines the SQLAlchemy ORM model that maps
#  directly to the "tasks" table in SQLite.
# ─────────────────────────────────────────────

from sqlalchemy import Column, Integer, String, Text, Date, Boolean, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from database import Base


class TaskDB(Base):
    """
    ORM model for a Task. Each instance represents one row in the 'tasks' table.
    SQLAlchemy automatically translates Python operations (add, query, delete)
    into the correct SQL statements.
    """
    __tablename__ = "tasks"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(255), nullable=False)
    description = Column(Text, default="")
    due_date = Column(Date, nullable=False)
    status = Column(String(50), default="To-Do")        # "To-Do", "In Progress", "Done"
    blocked_by_id = Column(Integer, ForeignKey("tasks.id"), nullable=True)  # Self-referencing FK
    is_recurring = Column(Boolean, default=False)
    recurrence_type = Column(String(20), nullable=True) # "Daily" or "Weekly"
    sort_order = Column(Integer, default=0)             # For future drag-and-drop ordering
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # Self-referential relationship: a task can point to another task as its blocker.
    # remote_side=[id] tells SQLAlchemy that 'id' is the "one" side of this relationship.
    blocked_by = relationship("TaskDB", remote_side=[id], foreign_keys=[blocked_by_id])