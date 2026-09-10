import json
import threading
import unittest
from urllib.request import Request, urlopen
from urllib.error import HTTPError
from http.server import ThreadingHTTPServer
from server import Handler, ROOMS

class ServerTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.server = ThreadingHTTPServer(('127.0.0.1', 0), Handler)
        cls.thread = threading.Thread(target=cls.server.serve_forever, daemon=True)
        cls.thread.start()
        cls.url = f'http://127.0.0.1:{cls.server.server_port}'
    @classmethod
    def tearDownClass(cls):
        cls.server.shutdown()
        cls.server.server_close()
        cls.thread.join()
    def post(self, path, data):
        req = Request(self.url + path, data=json.dumps(data).encode(), headers={'Content-Type': 'application/json'})
        with urlopen(req, timeout=3) as response:
            return json.load(response)
    def test_create_join(self):
        room = self.post('/rooms', {'name': 'Amigos', 'capacity': 4, 'private': True})
        self.assertEqual(len(room['code']), 6)
        self.assertEqual(self.post('/rooms/' + room['code'] + '/join', {})['name'], 'Amigos')
    def test_validation(self):
        for capacity in [0, 5, True, '4']:
            with self.assertRaises(HTTPError) as error:
                self.post('/rooms', {'name': 'Sala', 'capacity': capacity, 'private': True})
            self.assertEqual(error.exception.code, 400)
            error.exception.close()
    def test_missing(self):
        with self.assertRaises(HTTPError) as error:
            self.post('/rooms/XXXXXX/join', {})
        self.assertEqual(error.exception.code, 404)
        error.exception.close()
    def test_expiration(self):
        room = self.post('/rooms', {'name': 'Expirada', 'capacity': 2, 'private': False})
        ROOMS[room['code']]['created_at'] = 0
        with self.assertRaises(HTTPError) as error:
            self.post('/rooms/' + room['code'] + '/join', {})
        error.exception.close()
if __name__ == '__main__':
    unittest.main()
