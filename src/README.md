# 💻 Source Code

This directory contains all source code for the demo applications.

## Structure

### 🌐 Web Applications
- **`webapp-simple/`** - Node.js app with Express and Application Insights
- **`web/`** - .NET Core app (alternative)
- **`web-node/`** - Basic Node.js app

### ⚡ Azure Functions
- **`loadtest/`** - Functions for automatic load generation

## Technologies

### Node.js Application (`webapp-simple/`)
- **Express.js** - Web framework
- **Application Insights SDK** - Telemetry
- **Node.js 18 LTS** - Runtime

### .NET Application (`web/`)
- **ASP.NET Core** - Web framework
- **Application Insights** - Telemetry
- **.NET 8** - Runtime

## Configuration

### Required Environment Variables
```
APPLICATIONINSIGHTS_CONNECTION_STRING=your-connection-string
WEBSITE_NODE_DEFAULT_VERSION=18.12.0
```

### Available Endpoints
- `GET /` - Main dashboard
- `GET /health` - Health check
- `GET /api/products` - Products API
- `GET /error` - Error simulation
- `GET /load` - Load testing
- `GET /memory` - Memory testing
- `GET /dependencies` - Dependency simulation

## Local Development

```bash
# For Node.js
cd src/webapp-simple
npm install
npm start

# For .NET
cd src/web
dotnet restore
dotnet run
```
