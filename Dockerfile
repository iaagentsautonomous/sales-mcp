FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# 1. Copia os arquivos de configuração globais
COPY NuGet.config global.json Sales.Mcp.sln ./

# 2. Copia TODOS os arquivos .csproj mantendo a estrutura de pastas (para cache eficiente do restore)
COPY Sales.Mcp.Server/Sales.Mcp.Server.csproj Sales.Mcp.Server/
COPY Sales.Mcp.Application/Sales.Mcp.Application.csproj Sales.Mcp.Application/
COPY Sales.Mcp.DbBootstrap/Sales.Mcp.DbBootstrap.csproj Sales.Mcp.DbBootstrap/
# Se você criou projetos novos (Ex: Domain, Infrastructure), adicione as linhas correspondentes aqui:
# COPY Sales.Mcp.Domain/Sales.Mcp.Domain.csproj Sales.Mcp.Domain/

# Restaura apenas o projeto Server (traz Application transitivamente)
RUN dotnet restore Sales.Mcp.Server/Sales.Mcp.Server.csproj --configfile NuGet.config

# 3. CORREÇÃO PRINCIPAL: Copia TODO o código-fonte restante do repositório
# Isso garante que qualquer arquivo novo ou nova pasta de feature seja incluída no build
COPY . .

# 4. Publica o servidor MCP
RUN dotnet publish Sales.Mcp.Server/Sales.Mcp.Server.csproj -c Release -o /app/publish /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:8.0-bookworm-slim AS runtime
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=build /app/publish .

ENV ASPNETCORE_URLS=http://0.0.0.0:8080
ENV DOTNET_EnableDiagnostics=0

USER $APP_UID

ENTRYPOINT ["dotnet", "Sales.Mcp.Server.dll"]
