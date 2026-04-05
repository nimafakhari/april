import os
import redis
from http.server import BaseHTTPRequestHandler, HTTPServer

# read Redis connection info from environment variables
REDIS_HOST = os.getenv('REDIS_HOST', 'localhost')
REDIS_PORT = int(os.getenv('REDIS_PORT', 6379))

r = redis.Redis(host=REDIS_HOST, port=REDIS_PORT, db=0)

class CounterHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/' or self.path.startswith('/?'):
            counter_value = r.incr('my_counter')
            html = f'''
                <html>
                    <head>
                        <title>Redis v1</title>
                    </head>
                    <body>
                        <h1>Redis counter v1</h1>
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
    run()