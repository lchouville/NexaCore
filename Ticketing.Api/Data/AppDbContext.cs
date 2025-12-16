using Microsoft.EntityFrameworkCore;
using Ticketing.Api.Models;

namespace Ticketing.Api.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options)
        : base(options) { }

    public DbSet<Ticket> Tickets => Set<Ticket>();
}
