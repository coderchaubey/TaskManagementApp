# ─────────────────────────────────────────────
#  TaskMaster – Pydantic Schemas
#  These classes define the shape of data coming
#  IN (requests) and going OUT (responses) via the API.
#  Pydantic automatically validates and parses JSON.
# ─────────────────────────────────────────────

from pydantic import BaseModel, field_validator
from typing import Optional
from datetime import date
from enum import Enum


class StatusEnum(str, Enum):
    """Valid status values for a task."""
    todo = "To-Do"
    in_progress = "In Progress"
    done = "Done"


class RecurrenceEnum(str, Enum):
    """Valid recurrence interval options."""
    daily = "Daily"
    weekly = "Weekly"


class TaskBase(BaseModel):
    """
    Shared fields used by both TaskCreate and TaskResponse.
    Contains all the core task data.
    """
    title: str
    description: Optional[str] = ""
    due_date: date
    status: StatusEnum = StatusEnum.todo
    blocked_by_id: Optional[int] = None   # ID of the task that must be Done first
    is_recurring: bool = False
    recurrence_type: Optional[RecurrenceEnum] = None

    @field_validator("title")
    @classmethod
    def title_not_empty(cls, v):
        """Rejects blank titles — strips whitespace before checking."""
        if not v.strip():
            raise ValueError("Title cannot be empty")
        return v.strip()


class TaskCreate(TaskBase):
    """Schema for POST /tasks — all fields from TaskBase are required/defaulted."""
    pass


class TaskUpdate(BaseModel):
    """
    Schema for PUT /tasks/{id}.
    All fields are Optional so the client can send only what changed (partial update).
    """
    title: Optional[str] = None
    description: Optional[str] = None
    due_date: Optional[date] = None
    status: Optional[StatusEnum] = None
    blocked_by_id: Optional[int] = None
    is_recurring: Optional[bool] = None
    recurrence_type: Optional[RecurrenceEnum] = None

    @field_validator("title")
    @classmethod
    def title_not_empty(cls, v):
        if v is not None and not v.strip():
            raise ValueError("Title cannot be empty")
        return v.strip() if v else v


class TaskResponse(TaskBase):
    """
    Schema for API responses. Extends TaskBase with server-generated fields.
    'from_attributes = True' tells Pydantic to read from SQLAlchemy model attributes.
    """
    id: int
    sort_order: int

    model_config = {"from_attributes": True}