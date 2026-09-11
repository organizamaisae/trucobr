import os
from sqlalchemy import create_engine, String, JSON, select
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, sessionmaker

url = os.getenv('DATABASE_URL', 'sqlite:///./truco.db')
if url.startswith(('postgres://', 'postgresql://')):
    url = 'postgresql+psycopg://' + url.split('://', 1)[1]
engine = create_engine(url, **({'connect_args': {'check_same_thread': False}} if url.startswith('sqlite') else {'pool_pre_ping': True}))
Session = sessionmaker(engine, expire_on_commit=False)


class Base(DeclarativeBase):
    pass


class Record(Base):
    __tablename__ = 'truco_records'
    key: Mapped[str] = mapped_column(String(180), primary_key=True)
    kind: Mapped[str] = mapped_column(String(30), index=True)
    data: Mapped[dict] = mapped_column(JSON)


def get(db, key):
    row = db.get(Record, key)
    return row.data if row else None


def put(db, key, kind, data):
    row = db.get(Record, key)
    if row:
        row.data = data
        from sqlalchemy.orm.attributes import flag_modified
        flag_modified(row, 'data')
    else:
        db.add(Record(key=key, kind=kind, data=data))
    db.flush()


def all_of(db, kind):
    return [r.data for r in db.scalars(select(Record).where(Record.kind == kind))]
