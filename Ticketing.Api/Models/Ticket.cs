using System.ComponentModel.DataAnnotations;

namespace Ticketing.Api.Models;

public class Ticket
{
    public int Id { get; set; }

    [Required]
    [MaxLength(200)]
    public string Title { get; set; } = string.Empty;

    [MaxLength(2000)]
    public string? Description { get; set; }

    // Ticket status with enum string
    public TicketStatus Status { get; set; } = TicketStatus.Open;

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // Relation (optionnel pour EF Core)
    public List<Comment> Comments { get; set; } = new();
}

public enum TicketStatus
{
    Open,
    InProgress,
    Resolved,
    Closed
}
