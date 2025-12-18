// Ticketing.Api/Controllers/CommentsController.cs
using Microsoft.AspNetCore.Mvc;
using Ticketing.Api.Data;
using Ticketing.Api.Models;
using Microsoft.EntityFrameworkCore;

namespace Ticketing.Api.Controllers;

[ApiController]
[Route("api/tickets/{ticketId}/comments")]
public class CommentsController : ControllerBase
{
    private readonly AppDbContext _db;

    public CommentsController(AppDbContext db)
    {
        _db = db;
    }

    [HttpGet]
    public async Task<ActionResult<List<Comment>>> GetByTicket(int ticketId)
    {
        var comments = await _db.Comments
            .Where(c => c.TicketId == ticketId)
            .OrderBy(c => c.CreatedAt)
            .ToListAsync();

        return Ok(comments);
    }

    [HttpPost]
    public async Task<ActionResult<Comment>> Create(int ticketId, [FromBody] CreateCommentDto dto)
    {
        var ticketExists = await _db.Tickets.AnyAsync(t => t.Id == ticketId);
        if (!ticketExists)
            return NotFound("Ticket not found");

        var comment = new Comment
        {
            TicketId = ticketId,
            Content = dto.Content,
            CreatedAt = DateTime.UtcNow
        };

        _db.Comments.Add(comment);
        await _db.SaveChangesAsync();

        return CreatedAtAction(nameof(GetByTicket), new { ticketId }, comment);
    }
}

// DTO
public class CreateCommentDto
{
    public string Content { get; set; } = string.Empty;
}