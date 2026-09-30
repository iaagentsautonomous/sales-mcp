FROM ://microsoft.com AS build
WORKDIR /src

# 1. Copia os arquivos de configuração globais
COPY NuGet.config global.json Sales.Mcp.sln ./

# 2. Copia os arquivos .csproj para cache do restore
COPY Sales.Mcp.Server/Sales.Mcp.Server.csproj Sales.Mcp.Server/
COPY Sales.Mcp.Application/Sales.Mcp.Application.csproj Sales.Mcp.Application/
COPY Sales.Mcp.DbBootstrap/Sales.Mcp.DbBootstrap.csproj Sales.Mcp.DbBootstrap/

# Restaura as dependências usando as referências corretas
RUN dotnet restore Sales.Mcp.Server/Sales.Mcp.Server.csproj --configfile NuGet.config

# 3. Copia todo o restante do código-fonte
COPY . .

# 4. Publica o servidor MCP
RUN dotnet publish Sales.Mcp.Server/Sales.Mcp.Server.csproj -c Release -o /app/publish /p:UseAppHost=false

# 5. Estágio de Runtime (Corrigido o link ://microsoft.com)
FROM ://microsoft.com/dotnet/aspnet:8.0-bookworm-slim AS runtime
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=build /app/publish .

ENV ASPNETCORE_URLS=http://0.0.0
ENV DOTNET_EnableDiagnostics=0

USER $APP_UID

ENTRYPOINT ["dotnet", "Sales.Mcp.Server.dll"]
