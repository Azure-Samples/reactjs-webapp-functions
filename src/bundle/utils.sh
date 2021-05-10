#!/usr/bin/env bash

echo-azure-credentials() {
    echo $AZURE_CREDENTIALS
}

echo-web-api-hostname() {
    echo "The web API is located at: https://$1"
}

# Call requested function and pass arguments as-they-are
"$@"