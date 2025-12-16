using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Ticketing.Api.Data;
using Ticketing.Api.Dtos;
using Ticketing.Api.Models;

namespace Ticketing.Api.Controllers;

[ApiController]
[Route("api/tickets")]
public class TicketsController : ControllerBase
{
    private readonly AppDbContext _db;

    public TicketsController(AppDbContext db)
    {
        _db = db;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<Ticket>>> GetAll()
    {
        return Ok(await _db.Tickets.AsNoTracking().ToListAsync());
    }

    [HttpGet("{id:int}")]
    public async Task<ActionResult<Ticket>> GetById(int id)
    {
        var ticket = await _db.Tickets.FindAsync(id);
        if (ticket == null)
            return NotFound();

        return Ok(ticket);
    }

    [HttpPost]
    public async Task<ActionResult<Ticket>> Create(CreateTicketDto dto)
    {
        var ticket = new Ticket
        {
            Title = dto.Title,
            Description = dto.Description
        };

        _db.Tickets.Add(ticket);
        await _db.SaveChangesAsync();

        return CreatedAtAction(nameof(GetById), new { id = ticket.Id }, ticket);
    }

    [HttpPut("{id:int}")]
    public async Task<IActionResult> Update(int id, UpdateTicketDto dto)
    {
        var ticket = await _db.Tickets.FindAsync(id);
        if (ticket == null)
            return NotFound();

        ticket.Status = dto.Status;
        ticket.Description = dto.Description;

        await _db.SaveChangesAsync();
        return NoContent();
    }

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int id)
    {
        var ticket = await _db.Tickets.FindAsync(id);
        if (ticket == null)
            return NotFound();

        _db.Tickets.Remove(ticket);
        await _db.SaveChangesAsync();

        return NoContent();
    }
}
