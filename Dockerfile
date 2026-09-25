FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

COPY NuGet.config global.json Sales.Mcp.sln ./
COPY Sales.Mcp.Server/Sales.Mcp.Server.csproj Sales.Mcp.Server/
COPY Sales.Mcp.Application/Sales.Mcp.Application.csproj Sales.Mcp.Application/

RUN dotnet restore Sales.Mcp.Server/Sales.Mcp.Server.csproj --configfile NuGet.config

COPY Sales.Mcp.Server/. Sales.Mcp.Server/
COPY Sales.Mcp.Application/. Sales.Mcp.Application/

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
