using Sales.Mcp.DbBootstrap.Infrastructure;

namespace Sales.Mcp.Tests.Validation;

public sealed class SqlScriptBatchSplitterTests
{
    [Fact]
    public void Split_SeparatesBatchesOnGoStatements()
    {
        const string script = """
            SELECT 1
            GO
            SELECT 2
            GO
            """;

        var batches = SqlScriptBatchSplitter.Split(script);

        Assert.Equal(2, batches.Count);
        Assert.Contains("SELECT 1", batches[0]);
        Assert.Contains("SELECT 2", batches[1]);
    }
}
