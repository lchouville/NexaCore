// Ticketing.Ui/Models/CreateTicketModel.cs
using System.ComponentModel.DataAnnotations;

namespace Ticketing.Ui.Models;

public class CreateTicketModel
{
    [Required(ErrorMessage = "Le titre est requis.")]
    [MaxLength(200, ErrorMessage = "Le titre ne peut pas dépasser 200 caractères.")]
    public string Title { get; set; } = string.Empty;

    [MaxLength(1000, ErrorMessage = "La description est trop longue.")]
    public string? Description { get; set; }
}