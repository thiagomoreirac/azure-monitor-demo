#!/usr/bin/env bash
set -euo pipefail

echo "Installing Azure Developer CLI (azd)..."
curl -fsSL https://aka.ms/install-azd.sh | bash

# Ensure azd is available in future shells for the vscode user.
if ! grep -q 'PATH="$HOME/.azd/bin:$PATH"' "$HOME/.bashrc"; then
  echo 'export PATH="$HOME/.azd/bin:$PATH"' >> "$HOME/.bashrc"
fi
export PATH="$HOME/.azd/bin:$PATH"

if ! command -v npm >/dev/null 2>&1; then
  echo "npm not found. Installing nodejs and npm via apt..."
  sudo apt-get update
  sudo apt-get install -y nodejs npm
fi

if ! command -v npm >/dev/null 2>&1; then
  echo "ERROR: npm is still unavailable after installation. Rebuild the devcontainer without cache and retry."
  exit 1
fi

echo "Installing Azure Functions Core Tools v4..."
if sudo env "PATH=$PATH" npm --version >/dev/null 2>&1; then
  sudo env "PATH=$PATH" npm install -g azure-functions-core-tools@4 --unsafe-perm true
else
  echo "sudo cannot resolve npm in current PATH. Installing Functions Core Tools in user scope..."
  npm config set prefix "$HOME/.npm-global"
  if ! grep -q 'PATH="$HOME/.npm-global/bin:$PATH"' "$HOME/.bashrc"; then
    echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> "$HOME/.bashrc"
  fi
  export PATH="$HOME/.npm-global/bin:$PATH"
  npm install -g azure-functions-core-tools@4 --unsafe-perm true
fi

if ! command -v func >/dev/null 2>&1; then
  echo "ERROR: Azure Functions Core Tools installation did not produce the func command."
  exit 1
fi

echo "Installing Bicep CLI via Azure CLI..."
az bicep install

echo "Verifying toolchain..."
dotnet --version
node --version
pwsh --version
az --version | head -n 1
azd version
func --version
az bicep version

echo "Devcontainer setup complete."
