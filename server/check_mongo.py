"""Connectivity/transaction probe. Never prints database credentials."""
import sys
import secrets
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent.parent))


def main():
    try:
        from server.database import initialize,Session,put,get,STORAGE
        if STORAGE!='mongo':
            raise RuntimeError('Set TRUCO_STORAGE=mongo for this check.')
        initialize()
        class ProbeRollback(Exception): pass
        key='probe:'+secrets.token_hex(12)
        try:
            with Session.begin() as db:
                put(db,key,'probe',{'ok':True})
                assert get(db,key)['ok']
                raise ProbeRollback()
        except ProbeRollback:
            pass
        with Session() as db:
            assert get(db,key) is None
        print('PASS: MongoDB connection, transactional write/read and rollback.')
        return 0
    except Exception as error:
        print('FAIL: '+type(error).__name__+'. Check Atlas Network Access, credentials, TLS and cluster status. Credentials omitted.')
        return 1


if __name__=='__main__':
    raise SystemExit(main())
