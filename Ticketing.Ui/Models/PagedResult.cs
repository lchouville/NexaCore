namespace Ticketing.Ui.Models;

public class PagedResult<T>
{
    public int page { get; set; }
    public int pageSize { get; set; }
    public int totalCount { get; set; }
    public int totalPages { get; set; }
    public List<T> data { get; set; } = new();
}