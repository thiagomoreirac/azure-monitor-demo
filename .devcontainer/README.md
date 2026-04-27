# Devcontainer for Azure Deployment

This devcontainer is configured so you can deploy this repository to Azure from inside VS Code Dev Containers.

## Included tooling

- .NET 8 SDK
- Node.js (from base image)
- PowerShell
- Azure CLI (`az`)
- Azure Developer CLI (`azd`)
- Azure Functions Core Tools v4 (`func`)
- Bicep CLI (`az bicep`)

## First run

1. Open the repository in the container (`Dev Containers: Reopen in Container`).
2. Wait for post-create setup to complete.
3. Authenticate:
   - `az login`
4. Select subscription:
   - `az account set --subscription <SUBSCRIPTION_ID>`
5. Deploy:
   - `pwsh -File scripts/deploy.ps1 -ResourceGroupName <RESOURCE_GROUP_NAME> -Location "North Europe"`

## Useful checks

- `dotnet --version`
- `node --version`
- `pwsh --version`
- `az --version`
- `azd version`
- `func --version`
- `az bicep version`

## Notes

- Authentication is interactive and scoped to the container session.
- If deployment fails due to credentials, re-run `az login`.
- The repository deployment script expects ARM template files under `infra/` and publishes app artifacts from `src/web` and `src/loadtest`.
