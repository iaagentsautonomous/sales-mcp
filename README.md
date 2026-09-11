# Sales MCP Server

Servidor MCP de vendas em C# com ASP.NET Core, SQL Server containerizado e bootstrap automatizado do banco `A2A`.

## O que sobe

- `sqlserver`: SQL Server 2022 em container
- `db-bootstrap`: cria `A2A`, provisiona `mcp_reader` e aplica os scripts SQL
- `sales-mcp`: servidor MCP HTTP somente leitura em `http://localhost:8080/mcp`

## Pré-requisitos

- Docker e Docker Compose instalados
- Porta local `8080` livre

## Secrets locais

Crie os arquivos abaixo em `secrets/` a partir dos exemplos:

- `secrets/sql_sa_password.txt`
- `secrets/sql_reader_password.txt`
- `secrets/mcp_bearer_token.txt`

## Subir o ambiente

```powershell
docker compose up --build
```

## Validar

```powershell
curl http://localhost:8080/health/live
curl http://localhost:8080/health/ready
curl http://localhost:8080/version
```

## Testar uma chamada MCP

```powershell
$token = (Get-Content .\secrets\mcp_bearer_token.txt -Raw).Trim()
$body = @{
  jsonrpc = "2.0"
  id = "1"
  method = "tools/list"
  params = @{}
} | ConvertTo-Json -Depth 10

Invoke-RestMethod `
  -Method Post `
  -Uri "http://localhost:8080/mcp" `
  -Headers @{ Authorization = "Bearer $token" } `
  -ContentType "application/json" `
  -Body $body
```
