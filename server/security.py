import hashlib
import hmac
import secrets
import time


def password_hash(password):
    salt = secrets.token_hex(16)
    return salt + ':' + hashlib.scrypt(password.encode(), salt=salt.encode(), n=16384, r=8, p=1).hex()


def verify(password, encoded):
    salt, expected = encoded.split(':')
    actual = hashlib.scrypt(password.encode(), salt=salt.encode(), n=16384, r=8, p=1).hex()
    return hmac.compare_digest(actual, expected)


def digest(value):
    return hashlib.sha256(value.encode()).hexdigest()


def session():
    token = secrets.token_urlsafe(32)
    return token, dict(expires=time.time()+30*86400)
