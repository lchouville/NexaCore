var builder = WebApplication.CreateBuilder(args);

// Services
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

// Middleware
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

// Health Check Endpoint
app.MapGet("/health", () => Results.Ok("Healthy"));

app.UseHttpsRedirection();
app.UseAuthorization();

app.MapControllers();

app.Run();
