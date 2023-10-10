pipeline {
    agent any

    parameters {
        string(name: 'KONNECT_ADDRESS', defaultValue: 'https://eu.api.konghq.com', description: 'xxx')
        string(name: 'KONNECT_CONTROL_PLANE', defaultValue: 'hr-dev', description: 'xxx')
        string(name: 'KONNECT_PORTAL', defaultValue: '4abacaf1-47dc-4c07-83ff-a8801782277e', description: 'xxx')
        string(name: 'API_PRODUCT_NAME', defaultValue: 'Employees Directory', description: 'xxx')
        string(name: 'API_PRODUCT_DESCRIPTION', defaultValue: 'This is a sample Employee Directory Server based on the OpenAPI 3.0 specification.', description: 'xxx')
        choice(name: 'API_PRODUCT_PUBLISH', choices: [ "true", "false" ], description: 'xxx')
        string(name: 'API_PRODUCT_VERSION', defaultValue: '1.0.1', description: 'xxx')
        choice(name: 'API_PRODUCT_VERSION_STATUS', choices: [ "published", "deprecated", "unpublished" ], description: 'xxx')
        string(name: 'SERVICE_TAGS', defaultValue: 'employees-directory-v1-dev', description: 'xxx')
        string(name: 'KONNECT_CONTROL_PLANE_NAME_ENCODED', defaultValue: '')
        string(name: 'API_PRODUCT_NAME_ENCODED', defaultValue: '')
        string(name: 'KONNECT_CONTROL_PLANE_ID', defaultValue: '')
        string(name: 'SERVICE_ID', defaultValue: '')
        string(name: 'API_PRODUCT_ID', defaultValue: '')
    }

    environment {
        KONNECT_TOKEN       = credentials('konnect-token')
        KONG_GATEWAY_URL    = credentials('gateway-url')
    }

    stages {

        stage('Check Prerequisites') {
            steps {
                sh '''
                    # Check that deck has been installed
                    deck version
                '''

                sh '''
                    # Check Inso CLI is installed
                    inso -v
                '''

                sh '''
                    # Ping Kong Konnect to check connectivity                    
                    deck ping \
                        --konnect-addr ${KONNECT_ADDRESS} \
                        --konnect-token ${KONNECT_TOKEN} \
                        --konnect-control-plane-name ${KONNECT_CONTROL_PLANE}
                '''
            }
        }

        stage('Set Variables Test') {
            steps {
                script {
                    TMP_API_PRODUCT_NAME_ENCODED =  sh (script: 'echo ${API_PRODUCT_NAME} | sed \'s/ /%20/g\'', returnStdout: true).trim()
                    env.API_PRODUCT_NAME_ENCODED = TMP_API_PRODUCT_NAME_ENCODED

                    TMP_KONNECT_CONTROL_PLANE_NAME_ENCODED =  sh (script: 'echo ${KONNECT_CONTROL_PLANE} | sed \'s/ /%20/g\'', returnStdout: true).trim()
                    env.KONNECT_CONTROL_PLANE_NAME_ENCODED = TMP_KONNECT_CONTROL_PLANE_NAME_ENCODED

                    TMP_API_PRODUCT_VERSION =  sh (script: 'echo ${API_PRODUCT_VERSION}-${KONNECT_CONTROL_PLANE_NAME_ENCODED}', returnStdout: true).trim()
                    env.API_PRODUCT_VERSION = TMP_API_PRODUCT_VERSION

                    TMP_KONNECT_CONTROL_PLANE_ID =  sh (script: 'curl --url "${KONNECT_ADDRESS}/v2/control-planes?filter%5Bname%5D=${KONNECT_CONTROL_PLANE_NAME_ENCODED}" --header "accept: */*" --header "Authorization: Bearer ${KONNECT_TOKEN}" | jq -r \'.data[0].id\'', returnStdout: true).trim()
                    env.KONNECT_CONTROL_PLANE_ID = TMP_KONNECT_CONTROL_PLANE_ID
                    }
            }
        }

        stage('Lint OAS') {
            steps {
                sh '''
                    echo "Lint OAS with Inso CLI"
                    inso lint spec ./api/oas/spec.yml
                '''
            }
        }

        stage('Build Kong Declarative Configuration') {
            steps {
                sh '''
                    echo "Generate Kong declarative configuration from Spec"
                    
                    deck file openapi2kong \
                        --spec ./api/oas/spec.yml \
                        --format yaml \
                        --select-tag ${SERVICE_TAGS} \
                        --output-file kong-generated.yaml
                '''

                sh '''
                    echo "Merge Kong Configuration with Plugins"
                    
                    deck file merge ./kong-generated.yaml ./api/plugins/* -o kong.yaml
                '''

                sh '''
                    echo "Validate Kong declarative configuration"
                    
                    deck validate \
                        --state kong.yaml
                    
                    deck file merge ./kong-generated.yaml ./api/plugins/* -o kong.yaml
                '''
                
                sh '''
                    # Compare the new desired state represented in the generated Kong Declarative Configuration with the current state of the platform
                    deck diff \
                        --state kong.yaml \
                        --konnect-addr ${KONNECT_ADDRESS} \
                        --konnect-token ${KONNECT_TOKEN} \
                        --konnect-control-plane-name ${KONNECT_CONTROL_PLANE} \
                        --select-tag ${SERVICE_TAGS}
                 '''
            }
        }

        stage('Backup Existing Configuration') {
            steps {
                sh '''
                    # Use decK dump to take a backup of the entire Control Plane Configuration
                    deck dump \
                        --konnect-addr ${KONNECT_ADDRESS} \
                        --konnect-token ${KONNECT_TOKEN} \
                        --konnect-control-plane-name ${KONNECT_CONTROL_PLANE} \
                        --output-file kong-backup.yaml \
                        --yes
                 '''
            }
        }

        stage('Deploy Kong Declarative Configuration') {
            steps {
                sh '''
                    # Uses the deck sync command to push our generated Kong Declarative Configuration to the Kong Konnect Control Plane
                    deck sync \
                        --state kong.yaml \
                        --konnect-addr ${KONNECT_ADDRESS} \
                        --konnect-token ${KONNECT_TOKEN} \
                        --konnect-control-plane-name ${KONNECT_CONTROL_PLANE} \
                        --select-tag ${SERVICE_TAGS}
                 '''
            }
        }
        
        stage('Get Gateway Service ID') {
            steps {
                script {
                    TMP_SERVICE_ID =  sh(script: '''
                        curl --url "${KONNECT_ADDRESS}/v2/control-planes/${KONNECT_CONTROL_PLANE_ID}/core-entities/services?tags=${SERVICE_TAGS}" \
                        --header 'accept: application/json' \
                        --header "Authorization: Bearer ${KONNECT_TOKEN}" | jq -r \'.data[0].id\'
                        ''', returnStdout: true).trim()
                    
                    env.SERVICE_ID = TMP_SERVICE_ID

                    echo "Gateway Service ID: $TMP_SERVICE_ID"
                }
            }
        }

        stage('Check if API Product Exists') {
            steps {
                script {

                    TMP_API_PRODUCT_ID = sh(script: '''
                        curl --url "${KONNECT_ADDRESS}/v2/api-products?filter%5Bname%5D=${API_PRODUCT_NAME_ENCODED}" \
                        --header "Authorization: Bearer ${KONNECT_TOKEN}" \
                        --header "Accept: application/json" | jq -r \'.data[0].id\'
                    ''', returnStdout: true).trim()

                    env.API_PRODUCT_ID = TMP_API_PRODUCT_ID

                    echo "API Product ID: $TMP_API_PRODUCT_ID"
                }
            }        
        }

        stage('Create API Product') {
            when {
                expression { env.API_PRODUCT_ID == 'null' }
            }
            steps {
                script {

                    TMP_API_PRODUCT_ID = sh(script: '''
                        curl --url ${KONNECT_ADDRESS}/v2/api-products \
                        --header "Authorization: Bearer ${KONNECT_TOKEN}" \
                        --header "Content-Type: application/json" \
                        --data '{ "name": "'"$API_PRODUCT_NAME"'", "description": "'"$API_PRODUCT_DESCRIPTION"'" }' \
                        | jq -r .id
                    ''', returnStdout: true).trim()

                    env.API_PRODUCT_ID = TMP_API_PRODUCT_ID

                    echo "API Product ID: $TMP_API_PRODUCT_ID"

                }
            }        
        }

        stage('Upload API Product Documentation') {
            steps {
                sh '''
                    # Path to the folder containing files

                    PORTAL_ASSETS_FOLDER="./api/portal_assets/"

                    mkdir -p docs

                    for file_path in "$PORTAL_ASSETS_FOLDER"/*; do
                        
                        FILE_NAME=$(basename -- "$file_path")
                        FILE_NAME_NO_EXT=$(echo "$FILE_NAME" | cut -f 1 -d '.')
                        FILE_CONTENTS=$(base64 -w 0 -i ./api/portal_assets/$FILE_NAME)

                        # Create JSON payload with file name
                        FILE_CONTENTS_JSON='{"slug": "'"$FILE_NAME_NO_EXT"'","status": "published","title": "'"$FILE_NAME_NO_EXT"'","content": "'"$FILE_CONTENTS"'"}'

                        # Create a new document with JSON payload
                        echo "$FILE_CONTENTS_JSON" > ./docs/"$FILE_NAME_NO_EXT.json"

                    done

                    echo "Upload Static Documentation"

                    JSON_DOCS_FOLDER="./docs"

                    for file in "$JSON_DOCS_FOLDER"/*; do
                        curl --url ${KONNECT_ADDRESS}/v2/api-products/${API_PRODUCT_ID}/documents \
                            --header "Authorization: Bearer ${KONNECT_TOKEN}" -X POST \
                            --header 'Content-Type: application/json' \
                            --data @"$file"
                    done
                    '''
            }
        }
        
        stage('Create API Product Version and Upload OAS') {
            steps {
                sh '''
                    # Checks if an API Product Version already exists so that we don't create a duplicate each time this is run

                    KONNECT_API_PRODUCT_VERSION_ID=$(curl \
                        --request GET \
                        --url ${KONNECT_ADDRESS}/v2/api-products/${API_PRODUCT_ID}/product-versions?filter%5Bname%5D=${API_PRODUCT_VERSION} \
                        --header "Authorization: Bearer ${KONNECT_TOKEN}" \
                        --header "Accept: application/json" | jq -r '.data[0].id')

                    # Create a new API Product Version if the API Product Version ID from the previous script is null

                    if [[ "$KONNECT_API_PRODUCT_VERSION_ID" == "null" ]]; then
                        echo "KONNECT_API_PRODUCT_VERSION_ID is null or unset"

                        KONNECT_API_PRODUCT_VERSION_ID=$(curl -X POST \
                            --url ${KONNECT_ADDRESS}/v2/api-products/${API_PRODUCT_ID}/product-versions \
                            --header "Authorization: Bearer ${KONNECT_TOKEN}" \
                            --header "Content-Type: application/json" \
                            --header "Accept: application/json" \
                            --data '{
                                "name":"'"${API_PRODUCT_VERSION}"'",
                                "publish_status":"'"${API_PRODUCT_VERSION_STATUS}"'",
                                "deprecated":false,
                                "gateway_service": {
                                    "control_plane_id":"'"${KONNECT_CONTROL_PLANE_ID}"'",
                                    "id":"'"${SERVICE_ID}"'"
                                }
                            }' | jq -r '.id')
                    else
                        echo "KONNECT_API_PRODUCT_VERSION_ID is not null so skipping"
                    fi

                    # Add the OAS to the JSON Payload required by the Konnect Product API Version API and output as a file

                    echo "Prepare OpenAPI Specification"

                    base64 -w 0 ./api/oas/spec.yml > oas-encoded.yaml
                    
                    jq --null-input --arg content "$(<oas-encoded.yaml)" '{"name": "oas.yaml", "content": $content}' >> product_version_spec.json

                    # Upload the prepared OAS JSON Payload to the API Product Version

                    echo "Upload OpenAPI Specification to API Product Version"

                    curl \
                        --url "${KONNECT_ADDRESS}/v2/api-products/${API_PRODUCT_ID}/product-versions/${KONNECT_API_PRODUCT_VERSION_ID}/specifications" \
                        --header "Authorization: Bearer ${KONNECT_TOKEN}" \
                        --header "Content-Type: application/json" \
                        --header "Accept: application/json" \
                        --data @product_version_spec.json
                '''
            }
        }

        stage('Testing') {
            steps {
                sh '''
                    echo tbc
                 '''
            }
        }

        stage('Deploy to Developer Portal') {
            steps {
                sh '''

                echo "Publish to Developer Portal"

                if [[ "${API_PRODUCT_PUBLISH}" == true ]]; then
                    curl --request PATCH \
                    --url "${KONNECT_ADDRESS}/v2/api-products/${API_PRODUCT_ID}" \
                    --header "Authorization: Bearer ${KONNECT_TOKEN}" \
                    --header 'Content-Type: application/json' \
                    --header 'accept: application/json' \
                    --data '{"portal_ids":["'"$KONNECT_PORTAL"'"]}'
                fi

                 '''
            }
        }

    }
}