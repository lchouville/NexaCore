using Microsoft.EntityFrameworkCore;
using Ticketing.Api.Data;

var builder = WebApplication.CreateBuilder(args);
// add CORS
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowBlazorWasm", policy =>
    {
        policy.WithOrigins("http://localhost:5030") // URL de l'application Blazor WebAssembly
        .AllowAnyHeader()
        .AllowAnyMethod();
    });
});

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

// Utilise CORS (doit être avant UseAuthorization, UseEndpoints, etc.)
app.UseCors("AllowBlazorWasm");

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
app.UseRouting();
app.UseAuthorization();
app.MapControllers();

app.Run();
