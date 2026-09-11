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
                DB_NAME() AS DatabaseName,
                'sales' AS SchemaName,
                (SELECT COUNT(*) FROM sys.tables AS t INNER JOIN sys.schemas AS s ON s.schema_id = t.schema_id WHERE s.name = 'sales') AS TableCount,
                (SELECT COUNT(*) FROM sys.views AS v INNER JOIN sys.schemas AS s ON s.schema_id = v.schema_id WHERE s.name = 'sales') AS ViewCount,
                (SELECT COUNT(*) FROM sys.foreign_keys AS fk INNER JOIN sys.schemas AS s ON s.schema_id = fk.schema_id WHERE s.name = 'sales') AS ForeignKeyCount;
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
                c.TABLE_NAME AS TableName,
                c.COLUMN_NAME AS ColumnName,
                c.DATA_TYPE AS DataType,
                c.CHARACTER_MAXIMUM_LENGTH AS MaxLength,
                CASE WHEN c.IS_NULLABLE = 'YES' THEN CAST(1 AS bit) ELSE CAST(0 AS bit) END AS IsNullable,
                CASE WHEN k.COLUMN_NAME IS NOT NULL THEN CAST(1 AS bit) ELSE CAST(0 AS bit) END AS IsPrimaryKey
            FROM INFORMATION_SCHEMA.COLUMNS AS c
            LEFT JOIN
            (
                SELECT ku.TABLE_NAME, ku.COLUMN_NAME
                FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS AS tc
                INNER JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE AS ku
                    ON ku.CONSTRAINT_NAME = tc.CONSTRAINT_NAME
                   AND ku.TABLE_SCHEMA = tc.TABLE_SCHEMA
                WHERE tc.TABLE_SCHEMA = 'sales'
                  AND tc.CONSTRAINT_TYPE = 'PRIMARY KEY'
            ) AS k
                ON k.TABLE_NAME = c.TABLE_NAME
               AND k.COLUMN_NAME = c.COLUMN_NAME
            WHERE c.TABLE_SCHEMA = 'sales'
            ORDER BY c.TABLE_NAME, c.ORDINAL_POSITION;
            """;

        await using var connection = await _connectionFactory.OpenConnectionAsync(cancellationToken);
        var rows = (await connection.QueryAsync<TableColumnDto>(new CommandDefinition(sql, cancellationToken: cancellationToken))).AsList();

        return JsonSerializer.Serialize(new SchemaTablesDto(rows), JsonOptions);
    }

    private sealed record SchemaOverviewRow(string DatabaseName, string SchemaName, int TableCount, int ViewCount, int ForeignKeyCount);
}
