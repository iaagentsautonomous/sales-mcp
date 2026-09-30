# Estágio de Build (Usa o SDK do .NET 8 para compilar)
FROM ://microsoft.com AS build 
WORKDIR /src 
COPY NuGet.config global.json Sales.Mcp.sln ./ 
COPY Sales.Mcp.Server/Sales.Mcp.Server.csproj Sales.Mcp.Server/ 
COPY Sales.Mcp.Application/Sales.Mcp.Application.csproj Sales.Mcp.Application/ 
COPY Sales.Mcp.DbBootstrap/Sales.Mcp.DbBootstrap.csproj Sales.Mcp.DbBootstrap/ 
RUN dotnet restore Sales.Mcp.Server/Sales.Mcp.Server.csproj --configfile NuGet.config 
COPY . . 
RUN dotnet publish Sales.Mcp.Server/Sales.Mcp.Server.csproj -c Release -o /app/publish /p:UseAppHost=false 

# Estágio de Runtime (Usa o ASP.NET Core Runtime do .NET 8, muito menor e mais seguro)
FROM ://microsoft.com AS runtime 
RUN apt-get update \ 
    && apt-get install -y --no-install-recommends curl \ 
    && rm -rf /var/lib/apt/lists/* 
WORKDIR /app 
COPY --from=build /app/publish . 
# Corrigido a variável de ambiente para um formato de IP válido na porta padrão do .NET 8
ENV ASPNETCORE_URLS=http://0.0.0 
ENV DOTNET_EnableDiagnostics=0 
USER $APP_UID 
ENTRYPOINT ["dotnet", "Sales.Mcp.Server.dll"]
