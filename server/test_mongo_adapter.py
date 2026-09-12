"""Driver contract tests; Atlas connectivity is checked separately."""
from unittest.mock import MagicMock
import pytest
from server.test_truco import client  # selects isolated SQLite before importing API
from server import database as storage


def test_mongo_commit_and_document_queries(monkeypatch):
    collection=MagicMock()
    client=MagicMock()
    monkeypatch.setattr(storage,'mongo_collection',collection,raising=False)
    monkeypatch.setattr(storage,'mongo_client',client,raising=False)
    with storage.MongoSessions().begin() as unit:
        storage.put(unit,'user:one','user',{'chips':100})
        collection.find_one.return_value={'data':{'chips':100}}
        assert storage.get(unit,'user:one')=={'chips':100}
        collection.find.return_value=[{'data':{'chips':100}}]
        assert storage.all_of(unit,'user')==[{'chips':100}]
        storage.delete_sessions(unit,'one')
    session=client.start_session.return_value
    session.start_transaction.assert_called_once()
    session.commit_transaction.assert_called_once()
    session.end_session.assert_called_once()
    collection.replace_one.assert_called_once_with({'_id':'user:one'},{'_id':'user:one','kind':'user','data':{'chips':100}},upsert=True,session=session)
    collection.delete_many.assert_called_once_with({'kind':'session','data.uid':'one'},session=session)


def test_mongo_rolls_back_failed_operation(monkeypatch):
    collection=MagicMock();client=MagicMock()
    monkeypatch.setattr(storage,'mongo_collection',collection,raising=False)
    monkeypatch.setattr(storage,'mongo_client',client,raising=False)
    with pytest.raises(ValueError):
        with storage.MongoSessions().begin() as unit:
            storage.put(unit,'user:one','user',{'chips':0})
            raise ValueError('Insufficient balance for other participant')
    session=client.start_session.return_value
    session.abort_transaction.assert_called_once()
    session.commit_transaction.assert_not_called()
    session.end_session.assert_called_once()
