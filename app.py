import os
import time
import redis
from http.server import BaseHTTPRequestHandler, HTTPServer
from prometheus_client import start_http_server, Counter, Histogram, Gauge

REDIS_HOST = os.getenv('REDIS_HOST', 'localhost')
REDIS_PORT = int(os.getenv('REDIS_PORT', 6379))

r = redis.Redis(host=REDIS_HOST, port=REDIS_PORT, db=0)

# --- Metrics ---
REQUEST_COUNT = Counter(
    'app_requests_total',
    'Total HTTP requests',
    ['method', 'endpoint', 'status']
)

REQUEST_LATENCY = Histogram(
    'app_request_duration_seconds',
    'Request latency in seconds',
    ['endpoint'],
    buckets=[0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5]
)

REDIS_COUNTER_VALUE = Gauge(
    'redis_counter_current_value',
    'Current value of the Redis counter'
)

REDIS_ERROR_COUNT = Counter(
    'redis_errors_total',
    'Total Redis operation errors'
)


class CounterHandler(BaseHTTPRequestHandler):

    def do_GET(self):
        start = time.time()

        if self.path == '/' or self.path.startswith('/?'):
            self._handle_counter()
        elif self.path == '/slow':
            self._handle_slow()
        elif self.path == '/error':
            self._handle_error()
        else:
            REQUEST_COUNT.labels(method='GET', endpoint='unknown', status='404').inc()
            self.send_error(404)
            return

        duration = time.time() - start
        endpoint = self.path.split('?')[0] or '/'
        REQUEST_LATENCY.labels(endpoint=endpoint).observe(duration)

    def _handle_counter(self):
        try:
            counter_value = r.incr('my_counter')
            REDIS_COUNTER_VALUE.set(int(counter_value))
            REQUEST_COUNT.labels(method='GET', endpoint='/', status='200').inc()

            html = f'''<html>
  <head><title>Redis Counter</title></head>
  <body>
    <h1>Redis Counter</h1>
    <p>Current value: <strong>{counter_value}</strong></p>
    <p><a href="/">Increment</a> | <a href="/slow">Slow request</a> | <a href="/error">Trigger error</a></p>
    <p><small>Metrics: <a href="http://localhost:8001/metrics" target="_blank">:8001/metrics</a></small></p>
  </body>
</html>'''
            self._respond(200, html)
        except redis.RedisError as e:
            REDIS_ERROR_COUNT.inc()
            REQUEST_COUNT.labels(method='GET', endpoint='/', status='500').inc()
            self._respond(500, f'<h1>Redis Error</h1><p>{e}</p>')

    def _handle_slow(self):
        # Simulates a slow endpoint — triggers high latency alert in Prometheus
        time.sleep(1.5)
        REQUEST_COUNT.labels(method='GET', endpoint='/slow', status='200').inc()
        self._respond(200, '<h1>Slow response done</h1><p>This took 1.5s — check Grafana latency panel!</p>')

    def _handle_error(self):
        # Simulates a Redis error — triggers the RedisErrors alert
        REDIS_ERROR_COUNT.inc()
        REQUEST_COUNT.labels(method='GET', endpoint='/error', status='500').inc()
        self._respond(500, '<h1>Simulated Redis Error</h1><p>redis_errors_total was incremented — check Grafana!</p>')

    def _respond(self, code, html):
        self.send_response(code)
        self.send_header('Content-type', 'text/html; charset=utf-8')
        self.end_headers()
        self.wfile.write(html.encode('utf-8'))

    def log_message(self, format, *args):
        # Suppress default access log noise
        pass


def run(server_class=HTTPServer, handler_class=CounterHandler, host='0.0.0.0', port=8000):
    httpd = server_class((host, port), handler_class)
    print(f'App running on http://{host}:{port}')
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print('\nStopping...')
        httpd.server_close()


if __name__ == '__main__':
    start_http_server(8001)
    print('Prometheus metrics on http://0.0.0.0:8001/metrics')
    run()
