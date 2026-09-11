namespace Sales.Mcp.Application.Dtos;

public sealed record SchemaOverviewDto(
    string DatabaseName,
    string SchemaName,
    int TableCount,
    int ViewCount,
    int ForeignKeyCount,
    string GeneratedAtUtc);

public sealed record TableColumnDto(
    string TableName,
    string ColumnName,
    string DataType,
    int? MaxLength,
    bool IsNullable,
    bool IsPrimaryKey);

public sealed record SchemaTablesDto(IReadOnlyList<TableColumnDto> Columns);
