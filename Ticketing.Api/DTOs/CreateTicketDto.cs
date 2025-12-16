using System.ComponentModel.DataAnnotations;

namespace Ticketing.Api.Dtos;

public class CreateTicketDto
{
    [Required]
    [MaxLength(200)]
    public string Title { get; set; } = string.Empty;

    [MaxLength(2000)]
    public string? Description { get; set; }
}
