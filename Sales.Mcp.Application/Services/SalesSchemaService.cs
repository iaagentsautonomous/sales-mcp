using System.Text.Json;
using Dapper;
using Sales.Mcp.Application.Abstractions;
using Sales.Mcp.Application.Dtos;

namespace Sales.Mcp.Application.Services;

public sealed class SalesSchemaService
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web) { WriteIndented = true };
    private readonly ISqlConnectionFactory _connectionFactory;

    public SalesSchemaService(ISqlConnectionFactory connectionFactory)
    {
        _connectionFactory = connectionFactory;
    }

    public async Task<string> GetSchemaOverviewJsonAsync(CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                current_database() AS DatabaseName,
                'sales' AS SchemaName,
                (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'sales' AND table_type = 'BASE TABLE') AS TableCount,
                (SELECT COUNT(*) FROM information_schema.views WHERE table_schema = 'sales') AS ViewCount,
                (SELECT COUNT(*) FROM information_schema.table_constraints WHERE constraint_schema = 'sales' AND constraint_type = 'FOREIGN KEY') AS ForeignKeyCount;
            """;

        await using var connection = await _connectionFactory.OpenConnectionAsync(cancellationToken);
        var row = await connection.QuerySingleAsync<SchemaOverviewRow>(new CommandDefinition(sql, cancellationToken: cancellationToken));

        var dto = new SchemaOverviewDto(
            row.DatabaseName,
            row.SchemaName,
            row.TableCount,
            row.ViewCount,
            row.ForeignKeyCount,
            DateTime.UtcNow.ToString("O"));

        return JsonSerializer.Serialize(dto, JsonOptions);
    }

    public async Task<string> GetSchemaTablesJsonAsync(CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                c.table_name AS TableName,
                c.column_name AS ColumnName,
                c.data_type AS DataType,
                c.character_maximum_length AS MaxLength,
                (c.is_nullable = 'YES') AS IsNullable,
                (k.column_name IS NOT NULL) AS IsPrimaryKey
            FROM information_schema.columns AS c
            LEFT JOIN
            (
                SELECT ku.table_name, ku.column_name
                FROM information_schema.table_constraints AS tc
                INNER JOIN information_schema.key_column_usage AS ku
                    ON ku.constraint_name = tc.constraint_name
                   AND ku.table_schema = tc.table_schema
                WHERE tc.table_schema = 'sales'
                  AND tc.constraint_type = 'PRIMARY KEY'
            ) AS k
                ON k.table_name = c.table_name
               AND k.column_name = c.column_name
            WHERE c.table_schema = 'sales'
            ORDER BY c.table_name, c.ordinal_position;
            """;

        await using var connection = await _connectionFactory.OpenConnectionAsync(cancellationToken);
        var rows = (await connection.QueryAsync<TableColumnDto>(new CommandDefinition(sql, cancellationToken: cancellationToken))).AsList();

        return JsonSerializer.Serialize(new SchemaTablesDto(rows), JsonOptions);
    }

    private sealed record SchemaOverviewRow(string DatabaseName, string SchemaName, int TableCount, int ViewCount, int ForeignKeyCount);
}
