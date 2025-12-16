using Microsoft.EntityFrameworkCore;
using Ticketing.Api.Data;

var builder = WebApplication.CreateBuilder(args);

// Services
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
// Database
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseSqlite("Data Source=ticketing.db"));
// API Behavior
builder.Services.AddControllers()
    .ConfigureApiBehaviorOptions(options =>
    {
        options.SuppressModelStateInvalidFilter = false;
    });

var app = builder.Build();

// Pipeline
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}
// Health Check Endpoint
app.MapGet("/health", () => Results.Ok("Ticketing API is running."));
// Database Check Endpoint
app.MapGet("/health/db", async (AppDbContext db) =>
{
    try
    {
        await db.Database.ExecuteSqlRawAsync("SELECT 1");
        return Results.Ok("Database connection is healthy.");
    }
    catch (Exception ex)
    {
        return Results.Problem("Database connection failed: " + ex.Message);
    }
});

app.UseHttpsRedirection();
app.UseAuthorization();
app.MapControllers();

app.Run();
