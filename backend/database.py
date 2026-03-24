# ─────────────────────────────────────────────
#  TaskMaster – Database Configuration
#  Sets up the SQLAlchemy engine and session.
#  SQLite is used for simplicity — the database
#  is stored as a single file (taskmaster.db).
# ─────────────────────────────────────────────

from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

# SQLite file path — the .db file is created automatically on first run
DATABASE_URL = "sqlite:///./taskmaster.db"

# check_same_thread=False is required for SQLite when used with FastAPI
# because FastAPI may handle requests across multiple threads
engine = create_engine(
    DATABASE_URL,
    connect_args={"check_same_thread": False}
)

# SessionLocal is a factory — each request gets its own session instance
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Base class that all ORM models (like TaskDB) inherit from
Base = declarative_base()