// Ticketing.Ui/Models/Ticket.cs
namespace Ticketing.Ui.Models;

public class Ticket
{
    public int Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public int Status { get; set; } = 0;
    public DateTime CreatedAt { get; set; }

    // Get status text representation
    public string GetStatusText()
    {
        return Status switch
        {
            0 => "Open",
            1 => "In Progress",
            2 => "Resolved",
            3 => "Closed",
            _ => "Unknown"
        };
    }
}