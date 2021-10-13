#See https://aka.ms/containerfastmode to understand how Visual Studio uses this Dockerfile to build your images for faster debugging.
FROM mcr.microsoft.com/dotnet/core/aspnet:3.1 AS dotnet-builder
WORKDIR /app

FROM mcr.microsoft.com/dotnet/core/sdk:3.1 AS build
WORKDIR /src
COPY ["DockerAPI.csproj", "./"]
RUN dotnet restore "DockerAPI.csproj" -s https://artifactory.turkcell.com.tr/artifactory/api/nuget/virtual-nuget/
COPY . .
WORKDIR "/src"
RUN dotnet build "./DockerAPI.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "./DockerAPI.csproj" -c Release -o /app/out

FROM dotnet-builder AS final
WORKDIR /app
COPY --from=publish /app/out .
EXPOSE 51578
ENV ASPNETCORE_URLS="http://+:51578"
ENTRYPOINT ["dotnet", "DockerAPI.dll"]