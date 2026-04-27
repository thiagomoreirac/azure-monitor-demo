# 💻 Código Fuente

Este directorio contiene todo el código fuente de las aplicaciones de demostración.

## Estructura

### 🌐 Aplicaciones Web
- **`webapp-simple/`** - Aplicación Node.js con Express y Application Insights
- **`web/`** - Aplicación .NET Core (alternativa)
- **`web-node/`** - Aplicación Node.js básica

### ⚡ Azure Functions
- **`loadtest/`** - Functions para generación automática de carga

## Tecnologías

### Node.js Application (`webapp-simple/`)
- **Express.js** - Framework web
- **Application Insights SDK** - Telemetría
- **Node.js 18 LTS** - Runtime

### .NET Application (`web/`)
- **ASP.NET Core** - Framework web
- **Application Insights** - Telemetría
- **.NET 8** - Runtime

## Configuración

### Variables de Entorno Requeridas
```
APPLICATIONINSIGHTS_CONNECTION_STRING=your-connection-string
WEBSITE_NODE_DEFAULT_VERSION=18.12.0
```

### Endpoints Disponibles
- `GET /` - Dashboard principal
- `GET /health` - Health check
- `GET /api/products` - API de productos
- `GET /error` - Simulación de errores
- `GET /load` - Pruebas de carga
- `GET /memory` - Pruebas de memoria
- `GET /dependencies` - Simulación de dependencias

## Desarrollo Local

```bash
# Para Node.js
cd src/webapp-simple
npm install
npm start

# Para .NET
cd src/web
dotnet restore
dotnet run
```
