FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

COPY NuGet.config global.json Sales.Mcp.sln ./
COPY Sales.Mcp.DbBootstrap/Sales.Mcp.DbBootstrap.csproj Sales.Mcp.DbBootstrap/

RUN dotnet restore Sales.Mcp.DbBootstrap/Sales.Mcp.DbBootstrap.csproj --configfile NuGet.config

COPY Sales.Mcp.DbBootstrap/. Sales.Mcp.DbBootstrap/

RUN dotnet publish Sales.Mcp.DbBootstrap/Sales.Mcp.DbBootstrap.csproj -c Release -o /app/publish /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/runtime:8.0-bookworm-slim AS runtime
WORKDIR /app
COPY --from=build /app/publish .

ENTRYPOINT ["dotnet", "Sales.Mcp.DbBootstrap.dll"]
