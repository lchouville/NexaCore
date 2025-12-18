// Ticketing.Ui/Models/UpdateTicketModel.cs
using System.ComponentModel.DataAnnotations;

namespace Ticketing.Ui.Models;

public class UpdateTicketModel
{
    public int Id { get; set; }

    [Required]
    public string Title { get; set; } = string.Empty;

    public string? Description { get; set; }

    public int Status { get; set; }
}