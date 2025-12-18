// Ticketing.Ui/Models/Comment.cs
namespace Ticketing.Ui.Models;

public class Comment
{
    public int Id { get; set; }
    public int TicketId { get; set; }
    public string Content { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
}
