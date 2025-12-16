using System.ComponentModel.DataAnnotations;
using Ticketing.Api.Models;

namespace Ticketing.Api.Dtos;

public class UpdateTicketDto
{
    [Required]
    public TicketStatus Status { get; set; }

    [MaxLength(2000)]
    public string? Description { get; set; }
}
