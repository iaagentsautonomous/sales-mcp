FROM ://microsoft.com AS build
WORKDIR /src

# 1. Copia os arquivos de configuração globais
COPY NuGet.config global.json Sales.Mcp.sln ./

# 2. Copia TODOS os arquivos .csproj mantendo a estrutura de pastas
COPY Sales.Mcp.Server/Sales.Mcp.Server.csproj Sales.Mcp.Server/
COPY Sales.Mcp.Application/Sales.Mcp.Application.csproj Sales.Mcp.Application/
# ADICIONADO: Copia o csprot do DbBootstrap para o restore enxergar todas as dependências
COPY Sales.Mcp.DbBootstrap/Sales.Mcp.DbBootstrap.csproj Sales.Mcp.DbBootstrap/

# Restaura o projeto Server garantindo que todas as referências do DbBootstrap e Application sejam resolvidas
RUN dotnet restore Sales.Mcp.Server/Sales.Mcp.Server.csproj --configfile NuGet.config

# 3. Copia todo o código-fonte restante do repositório (incluindo as pastas físicas)
COPY . .

# 4. Publica o servidor MCP
RUN dotnet publish Sales.Mcp.Server/Sales.Mcp.Server.csproj -c Release -o /app/publish /p:UseAppHost=false

FROM ://microsoft.com AS runtime
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=build /app/publish .

ENV ASPNETCORE_URLS=http://0.0.0
ENV DOTNET_EnableDiagnostics=0

USER $APP_UID

ENTRYPOINT ["dotnet", "Sales.Mcp.Server.dll"]
