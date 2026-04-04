"""Integration tests for app.py with real Redis"""
import unittest
import redis
import requests
import time
import subprocess
import os
import signal
from threading import Thread

REDIS_HOST = os.getenv('REDIS_HOST', 'localhost')
REDIS_PORT = int(os.getenv('REDIS_PORT', 6379))
APP_URL = os.getenv('APP_URL', 'http://localhost:8000')


class TestAppIntegration(unittest.TestCase):
    """Integration tests requiring Redis and running app"""

    @classmethod
    def setUpClass(cls):
        """Set up integration test environment"""
        # Try to connect to Redis
        cls.redis_available = False
        try:
            cls.r = redis.Redis(
                host=REDIS_HOST,
                port=REDIS_PORT,
                decode_responses=True,
                socket_connect_timeout=2
            )
            cls.r.ping()
            cls.redis_available = True
            cls.r.delete('my_counter')  # Reset counter
        except (redis.ConnectionError, redis.TimeoutError):
            print(f"Warning: Redis not available at {REDIS_HOST}:{REDIS_PORT}")

    def setUp(self):
        """Skip tests if Redis not available"""
        if not self.redis_available:
            self.skipTest("Redis not available")

    def test_redis_connection(self):
        """Test connection to Redis"""
        assert self.redis_available
        response = self.r.ping()
        assert response is True

    def test_set_and_get_counter(self):
        """Test basic Redis operations"""
        self.r.set('test_key', 'test_value')
        value = self.r.get('test_key')
        assert value == 'test_value'

    def test_increment_counter(self):
        """Test counter increment in Redis"""
        self.r.delete('my_counter')
        
        # Increment counter 3 times
        self.r.incr('my_counter')
        self.r.incr('my_counter')
        value = self.r.incr('my_counter')
        
        assert value == 3

    def test_api_health_check(self):
        """Test API is responding (requires app running)"""
        try:
            response = requests.get(APP_URL, timeout=2)
            assert response.status_code == 200
            assert 'Redis counter' in response.text
        except requests.ConnectionError:
            self.skipTest(f"App not available at {APP_URL}")

    def test_api_returns_html(self):
        """Test API returns HTML content"""
        try:
            response = requests.get(APP_URL)
            assert response.headers['Content-Type'] == 'text/html; charset=utf-8'
            assert '<html>' in response.text
        except requests.ConnectionError:
            self.skipTest(f"App not available at {APP_URL}")

    def test_api_counter_displays(self):
        """Test API displays counter value"""
        try:
            self.r.delete('my_counter')
            self.r.set('my_counter', '0')
            
            response = requests.get(APP_URL)
            # Counter should be incremented to 1
            assert 'Current value' in response.text
            assert '<strong>1</strong>' in response.text
        except requests.ConnectionError:
            self.skipTest(f"App not available at {APP_URL}")

    def test_multiple_requests_increment_counter(self):
        """Test multiple requests increment counter"""
        try:
            self.r.delete('my_counter')
            
            # Make 3 requests
            for i in range(3):
                response = requests.get(APP_URL)
                assert response.status_code == 200
            
            # Check counter value
            counter = int(self.r.get('my_counter'))
            assert counter == 3
        except requests.ConnectionError:
            self.skipTest(f"App not available at {APP_URL}")

    def test_api_invalid_path_404(self):
        """Test API returns 404 for invalid paths"""
        try:
            response = requests.get(f'{APP_URL}/invalid')
            assert response.status_code == 404
        except requests.ConnectionError:
            self.skipTest(f"App not available at {APP_URL}")


class TestAppWithRedisContainer(unittest.TestCase):
    """Test app behavior with Redis in different states"""

    def setUp(self):
        """Set up test with Redis connection"""
        try:
            self.r = redis.Redis(
                host=REDIS_HOST,
                port=REDIS_PORT,
                decode_responses=True,
                socket_connect_timeout=2
            )
            self.r.ping()
        except (redis.ConnectionError, redis.TimeoutError):
            self.skipTest("Redis not available")

    def test_redis_persistence(self):
        """Test counter value persists in Redis"""
        self.r.delete('my_counter')
        
        # Set value
        self.r.set('my_counter', '100')
        
        # Get value immediately
        value = self.r.get('my_counter')
        assert value == '100'
        
        # Get value again (simulating another request)
        value = self.r.get('my_counter')
        assert value == '100'

    def test_counter_increments_atomically(self):
        """Test counter increments are atomic"""
        self.r.delete('my_counter')
        
        # Multiple increments
        for _ in range(10):
            self.r.incr('my_counter')
        
        # Should be exactly 10, not less due to race conditions
        value = int(self.r.get('my_counter'))
        assert value == 10


if __name__ == '__main__':
    unittest.main()
