using System.Text;
using System.Text.RegularExpressions;

namespace Sales.Mcp.DbBootstrap.Infrastructure;

public static partial class SqlScriptBatchSplitter
{
    [GeneratedRegex(@"^\s*GO(?:\s+\d+)?\s*(?:--.*)?$", RegexOptions.IgnoreCase)]
    private static partial Regex GoRegex();

    public static IReadOnlyList<string> Split(string script)
    {
        var batches = new List<string>();
        var builder = new StringBuilder();

        foreach (var line in script.Replace("\r\n", "\n").Split('\n'))
        {
            if (GoRegex().IsMatch(line))
            {
                Flush(builder, batches);
                continue;
            }

            builder.AppendLine(line);
        }

        Flush(builder, batches);
        return batches;
    }

    private static void Flush(StringBuilder builder, ICollection<string> batches)
    {
        var content = builder.ToString().Trim();
        if (!string.IsNullOrWhiteSpace(content))
        {
            batches.Add(content);
        }

        builder.Clear();
    }
}
