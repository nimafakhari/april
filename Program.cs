using System;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using StackExchange.Redis;

var redisHost = Environment.GetEnvironmentVariable("REDIS_HOST") ?? "localhost";
var redisPort = int.Parse(Environment.GetEnvironmentVariable("REDIS_PORT") ?? "6379");

// Connect to Redis
var redis = ConnectionMultiplexer.Connect($"{redisHost}:{redisPort}");
var db = redis.GetDatabase(0);

var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

app.MapGet("/", () => {
    var counterValue = db.StringIncrement("my_counter");
    return Results.Content(GenerateHtml(counterValue, "✅ Counter incremented to " + counterValue), "text/html");
});

app.MapGet("/decrement", () => {
    var current = db.StringGet("my_counter");
    long newValue = current.IsNull ? 0 : Math.Max(0, (long)current - 1);
    db.StringSet("my_counter", newValue);
    return Results.Content(GenerateHtml(newValue, "⬇️ Counter decremented to " + newValue), "text/html");
});

app.MapGet("/view", () => {
    var current = db.StringGet("my_counter");
    long counterValue = current.IsNull ? 0 : (long)current;
    return Results.Content(GenerateHtml(counterValue, "👁️ Viewing counter (not incremented)"), "text/html");
});

app.MapGet("/reset", () => {
    db.StringSet("my_counter", 0);
    return Results.Content(GenerateHtml(0, "🔄 Counter has been reset to 0"), "text/html");
});

app.MapGet("/set", (long value) => {
    if (value < 0)
        return Results.BadRequest("Value must be non-negative");
    db.StringSet("my_counter", value);
    return Results.Content(GenerateHtml(value, "✅ Counter set to " + value), "text/html");
});

app.MapFallback(() => Results.NotFound("<html><body><h1>404</h1><p>Endpoint not found</p></body></html>"));

app.Run("http://0.0.0.0:8000");

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
