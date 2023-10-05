## API Overview

This is a markdown file describing the employees directory service.  Please find the instructions on how to access this service below:

## 1. Application Registration

Register your application here to get a client ID and Secret:

<https://portal.mackong.net/my-apps>

## 2. Get Access Token

Use your Client ID and Secret to get an Access Token:

```
curl -X POST https://dev-78362292.okta.com/oauth2/default/v1/token -d "grant_type=client_credentials&client_id=$CLIENT_ID&client_secret=$CLIENT_SECRET&scope=foo"
```

## 2. Access Service

Use the Access Token to access the service via Kong:

```
curl http://localhost:8000/employees -H "Authorization: Bearer $ACCESS_TOKEN"
```