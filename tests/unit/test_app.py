"""Unit tests for app.py with mocked Redis"""
import unittest
from unittest.mock import patch, MagicMock, Mock
from io import BytesIO
import sys

# Mock redis before importing app
sys.modules['redis'] = MagicMock()


class TestCounterHandler(unittest.TestCase):
    """Test CounterHandler without Redis dependency"""

    def setUp(self):
        """Set up test fixtures"""
        # Import app here to ensure redis is mocked
        with patch('redis.Redis'):
            from app import CounterHandler
            self.CounterHandler = CounterHandler

    def _create_handler(self):
        """Create a handler instance without triggering __init__"""
        handler = self.CounterHandler.__new__(self.CounterHandler)
        handler.path = '/'
        handler.send_response = MagicMock()
        handler.send_header = MagicMock()
        handler.end_headers = MagicMock()
        handler.wfile = MagicMock()
        handler.send_error = MagicMock()
        return handler

    @patch('app.r')
    def test_get_root_path_increments_counter(self, mock_redis):
        """Test GET / increments counter and returns 200"""
        mock_redis.incr.return_value = 1

        handler = self._create_handler()
        handler.path = '/'
        handler.do_GET()

        # Verify redis was called
        mock_redis.incr.assert_called_once_with('my_counter')

        # Verify response was sent
        handler.send_response.assert_called_with(200)
        handler.send_header.assert_called()

    @patch('app.r')
    def test_get_with_query_params(self, mock_redis):
        """Test GET with query parameters"""
        mock_redis.incr.return_value = 5

        handler = self._create_handler()
        handler.path = '/?foo=bar'
        handler.do_GET()

        mock_redis.incr.assert_called_once_with('my_counter')
        handler.send_response.assert_called_with(200)

    @patch('app.r')
    def test_get_invalid_path_returns_404(self, mock_redis):
        """Test GET with invalid path returns 404"""
        handler = self._create_handler()
        handler.path = '/invalid'
        handler.do_GET()

        # Should send 404 error
        handler.send_error.assert_called_once_with(404)

        # Redis should NOT be called for invalid paths
        mock_redis.incr.assert_not_called()

    @patch('app.r')
    def test_response_contains_counter_value(self, mock_redis):
        """Test response HTML contains counter value"""
        mock_redis.incr.return_value = 42

        handler = self._create_handler()
        handler.path = '/'
        handler.do_GET()

        # Get the written response
        written_data = handler.wfile.write.call_args[0][0].decode('utf-8')

        # Verify counter value is in response
        assert '42' in written_data
        assert 'Redis counter' in written_data
        assert 'Current value' in written_data


if __name__ == '__main__':
    unittest.main()
