# Build stage
FROM mcr.microsoft.com/dotnet/sdk:8.0 as builder

WORKDIR /src

COPY RedisCounter.csproj ./
RUN dotnet restore

COPY . ./
RUN dotnet publish -c Release -o /app

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:8.0

WORKDIR /opt/app

COPY --from=builder /app .

EXPOSE 8000

ENTRYPOINT ["dotnet", "RedisCounter.dll"]
