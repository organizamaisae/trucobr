import os
from pathlib import Path
from dotenv import load_dotenv
load_dotenv(Path(__file__).resolve().parent.parent / '.env', override=False)
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
    key: Mapped[str] = mapped_column(String(512), primary_key=True)
    kind: Mapped[str] = mapped_column(String(30), index=True)
    data: Mapped[dict] = mapped_column(JSON)


def get(db, key):
    if isinstance(db, MongoUnit):
        row = db.collection.find_one({'_id':key},session=db.session)
        return row['data'] if row else None
    row = db.get(Record, key)
    return row.data if row else None


def put(db, key, kind, data):
    if isinstance(db, MongoUnit):
        db.collection.replace_one({'_id':key},{'_id':key,'kind':kind,'data':data},upsert=True,session=db.session)
        return
    row = db.get(Record, key)
    if row:
        row.data = data
        from sqlalchemy.orm.attributes import flag_modified
        flag_modified(row, 'data')
    else:
        db.add(Record(key=key, kind=kind, data=data))
    db.flush()


def all_of(db, kind):
    if isinstance(db, MongoUnit):
        return [r['data'] for r in db.collection.find({'kind':kind},session=db.session)]
    return [r.data for r in db.scalars(select(Record).where(Record.kind == kind))]


def delete(db,key):
    if isinstance(db,MongoUnit):
        db.collection.delete_one({'_id':key},session=db.session)
    else:
        row=db.get(Record,key)
        if row: db.delete(row)


def delete_sessions(db,uid):
    if isinstance(db,MongoUnit):
        db.collection.delete_many({'kind':'session','data.uid':uid},session=db.session)
    else:
        for row in db.scalars(select(Record).where(Record.kind=='session')):
            if row.data['uid']==uid: db.delete(row)


class MongoUnit:
    def __init__(self,write=False):
        self.write=write
        self.collection=mongo_collection
        self.session=None
    def __enter__(self):
        self.session=mongo_client.start_session()
        if self.write: self.session.start_transaction()
        return self
    def __exit__(self,kind,value,trace):
        try:
            if self.write:
                if kind is None: self.session.commit_transaction()
                else: self.session.abort_transaction()
        finally: self.session.end_session()


class MongoSessions:
    def __call__(self): return MongoUnit()
    def begin(self): return MongoUnit(write=True)


STORAGE=os.getenv('TRUCO_STORAGE','mongo')
if STORAGE=='mongo':
    from pymongo import MongoClient
    import certifi
    uri=os.getenv('MONGODB_URI','').strip()
    if not uri: raise RuntimeError('Configure MONGODB_URI no ambiente ou no arquivo .env.')
    mongo_client=MongoClient(uri,serverSelectionTimeoutMS=10000,connectTimeoutMS=10000,tlsCAFile=certifi.where())
    mongo_collection=mongo_client[os.getenv('MONGODB_DB','quizeid').strip()]['truco_br_records']
    Session=MongoSessions()


def initialize():
    if STORAGE=='mongo':
        mongo_client.admin.command('ping')
        mongo_collection.create_index('kind')
    else:
        Base.metadata.create_all(engine)
