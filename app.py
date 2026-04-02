import os
import redis
from http.server import BaseHTTPRequestHandler, HTTPServer
from prometheus_client import start_http_server, Counter

# read Redis connection info from environment variables
REDIS_HOST = os.getenv('REDIS_HOST', 'localhost')
REDIS_PORT = int(os.getenv('REDIS_PORT', 6379))

r = redis.Redis(host=REDIS_HOST, port=REDIS_PORT, db=0)

REQUEST_COUNT = Counter('app_requests_total', 'Total HTTP requests')
REDIS_COUNTER = Counter('redis_counter_increments_total', 'Total Redis counter increments')

class CounterHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/' or self.path.startswith('/?'):
            REQUEST_COUNT.inc()
            counter_value = r.incr('my_counter')
            REDIS_COUNTER.inc()
            html = f'''
                <html>
                    <head>
                        <title>Redis Counter</title>
                    </head>
                    <body>
                        <h1>Redis counter</h1>
                        <p>Current value: <strong>{counter_value}</strong></p>
                        <p><a href="/">Increment again</a></p>
                    </body>
                </html>
            '''

            self.send_response(200)
            self.send_header('Content-type', 'text/html; charset=utf-8')
            self.end_headers()
            self.wfile.write(html.encode('utf-8'))
        else:
            self.send_error(404)


def run(server_class=HTTPServer, handler_class=CounterHandler, host='0.0.0.0', port=8000):
    server_address = (host, port)
    httpd = server_class(server_address, handler_class)
    print(f'Serving on http://{host}:{port}')
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print('\nStopping server...')
        httpd.server_close()


if __name__ == '__main__':
    start_http_server(8001)
    print('Prometheus metrics exposed on http://0.0.0.0:8001/metrics')
    run()
