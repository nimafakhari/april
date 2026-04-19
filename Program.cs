using System;
using System.Net;
using System.Text;
using StackExchange.Redis;

var redisHost = Environment.GetEnvironmentVariable("REDIS_HOST") ?? "localhost";
var redisPort = int.Parse(Environment.GetEnvironmentVariable("REDIS_PORT") ?? "6379");

// Connect to Redis
var redis = ConnectionMultiplexer.Connect($"{redisHost}:{redisPort}");
var db = redis.GetDatabase(0);

// Create HTTP server
var listener = new HttpListener();
listener.Prefixes.Add("http://0.0.0.0:8000/");
listener.Start();
Console.WriteLine("🚀 Serving on http://0.0.0.0:8000");

try
{
    while (true)
    {
        HttpListenerContext context = listener.GetContext();
        HttpListenerRequest request = context.Request;
        HttpListenerResponse response = context.Response;

        try
        {
            string path = request.Url.AbsolutePath;
            long counterValue = 0;

            if (path == "/" || path == "")
            {
                // Increment counter
                counterValue = db.StringIncrement("my_counter");
                response.StatusCode = 200;
                byte[] buffer = Encoding.UTF8.GetBytes(GenerateHtml(counterValue, "✅ Counter incremented to " + counterValue));
                response.ContentLength64 = buffer.Length;
                response.OutputStream.Write(buffer, 0, buffer.Length);
            }
            else if (path == "/decrement")
            {
                // Decrement counter
                var current = db.StringGet("my_counter");
                long newValue = current.IsNull ? 0 : Math.Max(0, (long)current - 1);
                db.StringSet("my_counter", newValue);
                counterValue = newValue;
                response.StatusCode = 200;
                byte[] buffer = Encoding.UTF8.GetBytes(GenerateHtml(counterValue, "⬇️ Counter decremented to " + counterValue));
                response.ContentLength64 = buffer.Length;
                response.OutputStream.Write(buffer, 0, buffer.Length);
            }
            else if (path == "/view")
            {
                // View without incrementing
                var current = db.StringGet("my_counter");
                counterValue = current.IsNull ? 0 : (long)current;
                response.StatusCode = 200;
                byte[] buffer = Encoding.UTF8.GetBytes(GenerateHtml(counterValue, "👁️ Viewing counter (not incremented)"));
                response.ContentLength64 = buffer.Length;
                response.OutputStream.Write(buffer, 0, buffer.Length);
            }
            else if (path == "/reset")
            {
                // Reset counter
                db.StringSet("my_counter", 0);
                response.StatusCode = 200;
                byte[] buffer = Encoding.UTF8.GetBytes(GenerateHtml(0, "🔄 Counter has been reset to 0"));
                response.ContentLength64 = buffer.Length;
                response.OutputStream.Write(buffer, 0, buffer.Length);
            }
            else if (path.StartsWith("/set"))
            {
                // Set custom value
                var query = request.Url.Query;
                if (query.Contains("value="))
                {
                    var valueStr = query.Split("value=")[1].Split("&")[0];
                    if (long.TryParse(valueStr, out long newValue) && newValue >= 0)
                    {
                        db.StringSet("my_counter", newValue);
                        counterValue = newValue;
                        response.StatusCode = 200;
                        byte[] buffer = Encoding.UTF8.GetBytes(GenerateHtml(counterValue, "✅ Counter set to " + counterValue));
                        response.ContentLength64 = buffer.Length;
                        response.OutputStream.Write(buffer, 0, buffer.Length);
                    }
                    else
                    {
                        response.StatusCode = 400;
                        byte[] buffer = Encoding.UTF8.GetBytes("<html><body><h1>Error</h1><p>Invalid value</p></body></html>");
                        response.ContentLength64 = buffer.Length;
                        response.OutputStream.Write(buffer, 0, buffer.Length);
                    }
                }
            }
            else
            {
                response.StatusCode = 404;
                byte[] buffer = Encoding.UTF8.GetBytes("<html><body><h1>404</h1><p>Endpoint not found</p></body></html>");
                response.ContentLength64 = buffer.Length;
                response.OutputStream.Write(buffer, 0, buffer.Length);
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error: {ex.Message}");
            response.StatusCode = 500;
            byte[] buffer = Encoding.UTF8.GetBytes($"<html><body><h1>Error</h1><p>{ex.Message}</p></body></html>");
            response.ContentLength64 = buffer.Length;
            response.OutputStream.Write(buffer, 0, buffer.Length);
        }

        response.OutputStream.Close();
    }
}
catch (KeyboardInterrupt)
{
    Console.WriteLine("\nStopping server...");
}
finally
{
    listener.Stop();
}

string GenerateHtml(long counterValue, string message)
{
    return $@"
<!DOCTYPE html>
<html>
    <head>
        <title>Redis Counter (.NET)</title>
        <style>
            body {{ font-family: Arial, sans-serif; margin: 40px; background-color: #f5f5f5; }}
            .container {{ background-color: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); max-width: 600px; }}
            h1 {{ color: #333; }}
            .counter {{ font-size: 48px; font-weight: bold; color: #007bff; text-align: center; margin: 20px 0; }}
            .message {{ color: green; font-weight: bold; margin: 15px 0; }}
            .controls {{ display: flex; gap: 10px; flex-wrap: wrap; margin: 20px 0; }}
            a, button {{ padding: 10px 20px; margin: 5px; border: none; border-radius: 4px; text-decoration: none; cursor: pointer; font-size: 14px; }}
            .btn-primary {{ background-color: #007bff; color: white; }}
            .btn-primary:hover {{ background-color: #0056b3; }}
            .btn-danger {{ background-color: #dc3545; color: white; }}
            .btn-danger:hover {{ background-color: #c82333; }}
            .btn-secondary {{ background-color: #6c757d; color: white; }}
            .btn-secondary:hover {{ background-color: #5a6268; }}
            input {{ padding: 8px; font-size: 14px; }}
            .tech-badge {{ display: inline-block; background: #007bff; color: white; padding: 5px 10px; border-radius: 20px; margin-top: 20px; font-size: 12px; }}
        </style>
    </head>
    <body>
        <div class=""container"">
            <h1>🔢 Redis Counter</h1>
            <p style=""font-size: 12px; color: #666;""><strong>Built with C# & ASP.NET</strong></p>
            <div class=""counter"">{counterValue}</div>
            <div class=""message"">{message}</div>
            <div class=""controls"">
                <a href=""/"" class=""btn-primary"">➕ Increment</a>
                <a href=""/decrement"" class=""btn-secondary"">➖ Decrement</a>
                <a href=""/view"" class=""btn-secondary"">👁️ View</a>
                <a href=""/reset"" class=""btn-danger"" onclick=""return confirm('Reset counter to 0?');"">🔄 Reset</a>
            </div>
            <div style=""margin-top: 30px;"">
                <h3>Set Custom Value:</h3>
                <form action=""/set"" method=""get"" style=""display: flex; gap: 10px;"">
                    <input type=""number"" name=""value"" placeholder=""Enter value"" required>
                    <button type=""submit"" class=""btn-primary"">Set</button>
                </form>
            </div>
            <span class=""tech-badge"">🔧 C# with Redis</span>
        </div>
    </body>
</html>";
}
