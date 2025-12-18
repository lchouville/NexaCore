namespace Ticketing.Api.Models;

public class Comment
{
    public int Id { get; set; }
    public string Content { get; set; } = null!;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public int TicketId { get; set; }
}
