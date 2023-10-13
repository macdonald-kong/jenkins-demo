# Jenkins Demo for Kong

## Overview

This demonstration repository will use Jenkins to execute the following steps to deploy the Employees Directory API to Kong Konnect:
  
- Lints the OpenAPI Spec (OAS) using Inso CLI
- Generate Kong declarative configuration from OAS using Inso CLI
- Upgrades Version of Kong declarative configuration using Inso CLI
- Uploads Kong declarative config to Artifact Repository
- Validates Kong declarative config using decK
- Diffs declarative config using decK
- Backup existing Kong configuration using decK
- Creates API Product
- Prepares Static Documentation
- Uploads Static Documentation using Konnect Admin API
- Deploys declarative config to development environment using decK
- Prepares OAS 
- Uploads OAS to Product Version using Konnect Admin API
- Runs Unit Tests using Inso CLI
- Publishes Product Version to Developer Portal using Konnect Admin API

# Deploy Jenkins

# Deploy Kong Gateway


