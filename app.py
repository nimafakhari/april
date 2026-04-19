import os
import redis
from http.server import BaseHTTPRequestHandler, HTTPServer

# read Redis connection info from environment variables
REDIS_HOST = os.getenv('REDIS_HOST', 'localhost')
REDIS_PORT = int(os.getenv('REDIS_PORT', 6380))

r = redis.Redis(host=REDIS_HOST, port=REDIS_PORT, db=0)

class CounterHandler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        """Suppress default logging"""
        pass
    
    def get_counter_value(self):
        """Get current counter value"""
        try:
            value = r.get('my_counter')
            return int(value) if value else 0
        except:
            return 0
    
    def render_page(self, counter_value, message=''):
        """Render HTML page with counter and controls"""
        message_html = f'<p style="color: green; font-weight: bold;">{message}</p>' if message else ''
        html = f'''
            <html>
                <head>
                    <title>Redis Counter</title>
                    <style>
                        body {{ font-family: Arial, sans-serif; margin: 40px; background-color: #f5f5f5; }}
                        .container {{ background-color: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); max-width: 600px; }}
                        h1 {{ color: #333; }}
                        .counter {{ font-size: 48px; font-weight: bold; color: #007bff; text-align: center; margin: 20px 0; }}
                        .controls {{ display: flex; gap: 10px; flex-wrap: wrap; margin: 20px 0; }}
                        a, button {{ padding: 10px 20px; margin: 5px; border: none; border-radius: 4px; text-decoration: none; cursor: pointer; font-size: 14px; }}
                        .btn-primary {{ background-color: #007bff; color: white; }}
                        .btn-primary:hover {{ background-color: #0056b3; }}
                        .btn-danger {{ background-color: #dc3545; color: white; }}
                        .btn-danger:hover {{ background-color: #c82333; }}
                        .btn-secondary {{ background-color: #6c757d; color: white; }}
                        .btn-secondary:hover {{ background-color: #5a6268; }}
                        input {{ padding: 8px; font-size: 14px; }}
                        {message_html}
                    </style>
                </head>
                <body>
                    <div class="container">
                        <h1>🔢 Redis Counter</h1>
                        <div class="counter">{counter_value}</div>
                        {message_html}
                        <div class="controls">
                            <a href="/" class="btn-primary">➕ Increment</a>
                            <a href="/decrement" class="btn-secondary">➖ Decrement</a>
                            <a href="/view" class="btn-secondary">👁️ View</a>
                            <a href="/reset" class="btn-danger" onclick="return confirm('Reset counter to 0?');">🔄 Reset</a>
                        </div>
                        <div style="margin-top: 30px;">
                            <h3>Set Custom Value:</h3>
                            <form action="/set" method="get" style="display: flex; gap: 10px;">
                                <input type="number" name="value" placeholder="Enter value" required>
                                <button type="submit" class="btn-primary">Set</button>
                            </form>
                        </div>
                    </div>
                </body>
            </html>
        '''
        return html
    
    def send_html_response(self, html):
        """Send HTML response"""
        self.send_response(200)
        self.send_header('Content-type', 'text/html; charset=utf-8')
        self.end_headers()
        self.wfile.write(html.encode('utf-8'))
    
    def do_GET(self):
        try:
            if self.path == '/' or self.path == '/?':
                # Increment counter
                counter_value = r.incr('my_counter')
                html = self.render_page(counter_value, f'✅ Counter incremented to {counter_value}')
                self.send_html_response(html)
            
            elif self.path == '/decrement':
                # Decrement counter (don't go below 0)
                current = self.get_counter_value()
                new_value = max(0, current - 1)
                r.set('my_counter', new_value)
                html = self.render_page(new_value, f'⬇️ Counter decremented to {new_value}')
                self.send_html_response(html)
            
            elif self.path == '/view':
                # View counter without incrementing
                counter_value = self.get_counter_value()
                html = self.render_page(counter_value, '👁️ Viewing counter (not incremented)')
                self.send_html_response(html)
            
            elif self.path == '/reset':
                # Reset counter to 0
                r.set('my_counter', 0)
                html = self.render_page(0, '🔄 Counter has been reset to 0')
                self.send_html_response(html)
            
            elif self.path.startswith('/set'):
                # Set counter to custom value
                from urllib.parse import urlparse, parse_qs
                parsed = urlparse(self.path)
                params = parse_qs(parsed.query)
                
                if 'value' in params:
                    try:
                        new_value = int(params['value'][0])
                        if new_value < 0:
                            raise ValueError('Value must be non-negative')
                        r.set('my_counter', new_value)
                        html = self.render_page(new_value, f'✅ Counter set to {new_value}')
                        self.send_html_response(html)
                    except (ValueError, IndexError):
                        self.send_error(400, 'Invalid value. Please provide a non-negative integer.')
                else:
                    self.send_error(400, 'Missing "value" parameter.')
            
            else:
                self.send_error(404, 'Endpoint not found')
        
        except Exception as e:
            print(f'Error: {e}')
            self.send_error(500, f'Server error: {str(e)}')


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