namespace Sales.Mcp.Server.Middleware;

public static class AllowedOriginEvaluator
{
    public static bool IsAllowed(string originHeader, IReadOnlySet<string> allowedOrigins)
    {
        if (allowedOrigins.Count == 0)
        {
            return true;
        }

        if (!Uri.TryCreate(originHeader, UriKind.Absolute, out var origin))
        {
            return false;
        }

        var normalized = origin.GetLeftPart(UriPartial.Authority).TrimEnd('/');
        return allowedOrigins.Contains(normalized);
    }
}
