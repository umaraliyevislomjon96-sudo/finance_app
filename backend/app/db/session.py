import logging
from typing import AsyncGenerator, Optional
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy import text
from ..core.config import settings

logger = logging.getLogger("aurora.db")

# Asynchronous engine with connection pooling
engine = None
AsyncSessionLocal = None

try:
    if settings.DATABASE_URL:
        engine = create_async_engine(
            settings.DATABASE_URL,
            echo=False,
            pool_size=10,
            max_overflow=20,
            pool_pre_ping=True
        )
        AsyncSessionLocal = async_sessionmaker(
            bind=engine,
            class_=AsyncSession,
            expire_on_commit=False,
            autocommit=False,
            autoflush=False
        )
except Exception as e:
    logger.warning(f"Could not initialize primary asyncpg database engine: {e}")


async def get_db_session(current_user_id: Optional[str] = None) -> AsyncGenerator[Optional[AsyncSession], None]:
    """
    Dependency that yields an active database session.
    Automatically sets the PostgreSQL RLS session variable `app.current_user_id`
    to enforce strict tenant isolation in PostgreSQL 16+.
    """
    if AsyncSessionLocal is None:
        yield None
        return

    async with AsyncSessionLocal() as session:
        try:
            if current_user_id:
                # Set session variable for Row Level Security (RLS)
                await session.execute(
                    text("SET LOCAL app.current_user_id = :uid"),
                    {"uid": str(current_user_id)}
                )
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()
