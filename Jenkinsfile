
/**
*
* Basic Jenkinsfile for Kong Konnect Demonstrations
*
* Author: David MacDonald
* Contact: david.macdonald@konghq.com
* Website: https://konghq.com/
*
* DISCLAIMER: DO NOT USE THIS IN PRODUCTION - FOR DEMONSTRATION PURPOSES ONLY
*
*/

pipeline {
    agent any

    environment {
        KONNECT_TOKEN       = credentials('konnect-token')
        KONG_GATEWAY_URL    = credentials('gateway-url')
    }

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

    stages {

        stage('Check Prerequisites') {
            steps {

                // Check that deck has been installed
                sh 'deck version'

                // Check Inso CLI is installed
                sh ' inso -v'

                // Ping Kong Konnect to check connectivity
                sh '''
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
                    // The Konnect Control Plane Name and API Product Names might include characters that need to be URL encoded.
                    TMP_API_PRODUCT_NAME_ENCODED =  sh (script: 'echo ${API_PRODUCT_NAME} | sed \'s/ /%20/g\'', returnStdout: true).trim()
                    env.API_PRODUCT_NAME_ENCODED = TMP_API_PRODUCT_NAME_ENCODED

                    TMP_KONNECT_CONTROL_PLANE_NAME_ENCODED =  sh (script: 'echo ${KONNECT_CONTROL_PLANE} | sed \'s/ /%20/g\'', returnStdout: true).trim()
                    env.KONNECT_CONTROL_PLANE_NAME_ENCODED = TMP_KONNECT_CONTROL_PLANE_NAME_ENCODED

                    // The API Product Version name will not be unique if just based on what we extract from the OAS - we need to add the Runtime Group Name to this
                    TMP_API_PRODUCT_VERSION =  sh (script: 'echo ${API_PRODUCT_VERSION}-${KONNECT_CONTROL_PLANE_NAME_ENCODED}', returnStdout: true).trim()
                    env.API_PRODUCT_VERSION = TMP_API_PRODUCT_VERSION
                    
                    // Use the Konnect Control Plane Name to search for the ID using the Konnect Control Plane API
                    TMP_KONNECT_CONTROL_PLANE_ID =  sh (script: 'curl --url "${KONNECT_ADDRESS}/v2/control-planes?filter%5Bname%5D=${KONNECT_CONTROL_PLANE_NAME_ENCODED}" --header "accept: */*" --header "Authorization: Bearer ${KONNECT_TOKEN}" | jq -r \'.data[0].id\'', returnStdout: true).trim()
                    env.KONNECT_CONTROL_PLANE_ID = TMP_KONNECT_CONTROL_PLANE_ID
                    }
            }
        }

        stage('Lint OAS') {
            steps {
                // Lint OAS with Inso CLI
                sh 'inso lint spec ./api/oas/spec.yml'
            }
        }

        stage('Build Kong Declarative Configuration') {
            steps {
                // Generate Kong declarative configuration from Spec
                sh '''
                    deck file openapi2kong \
                        --spec ./api/oas/spec.yml \
                        --format yaml \
                        --select-tag ${SERVICE_TAGS} \
                        --output-file kong-generated.yaml
                '''

                // Merge Kong Configuration with Plugins
                sh 'deck file merge ./kong-generated.yaml ./api/plugins/* -o kong.yaml'

                // Validate Kong declarative configuration
                sh '''
                    deck validate \
                        --state kong.yaml
                '''
                
                // Compare the new desired state represented in the generated Kong Declarative Configuration with the current state of the platform
                sh '''
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
                // Use decK dump to take a backup of the entire Control Plane Configuration
                sh '''
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
                // Uses the deck sync command to push our generated Kong Declarative Configuration to the Kong Konnect Control Plane
                sh '''
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
                    // Set a Variable containing the Service ID of the Service that we deployed - we need this to link the API Product to a Kong Service
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
                    // Checks if an API Product Version already exists so that we don't create a duplicate each time this is run
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

        stage('Delete Current API Product Documentation') {
            when {
                expression { env.API_PRODUCT_ID != 'null' }
            steps {
                script {
                // Delete the current API Documentation so that we can upload the new ones with any updates
                // Very inneficient - will improve later
                DOCUMENTS_JSON = sh(script: '''
                    curl --url ${KONNECT_ADDRESS}/v2/api-products/${API_PRODUCT_ID}/documents \
                    --header "Authorization: Bearer ${KONNECT_TOKEN}" \
                    --header "Content-Type: application/json" \
                ''', returnStdout: true).trim()

                echo "Currently available documentation: $DOCUMENTS_JSON"

                sh '''
                    # Extract document IDs and send DELETE requests
                    ids=$(echo "$DOCUMENTS_JSON" | jq -r '.data[].id')

                    for id in $ids; do
                        curl -X DELETE --url $KONNECT_ADDRESS/v2/api-products/$API_PRODUCT_ID/documents/$id \
                            --header "Authorization: Bearer ${KONNECT_TOKEN}" 
                    done
                '''
                }
            }
        }

        stage('Create API Product') {
            when {
                expression { env.API_PRODUCT_ID == 'null' }
            }
            steps {
                script {
                    // Create a new API Product if the API Product ID from the previous script is null
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
                // Base64 encode each markdown file in the portal_assets folder and inject each into the required json payload to send to the Konnect API Products API
                sh '''
                    mkdir -p docs

                    for file_path in ./api/portal_assets/*; do
                        FILE_NAME=$(basename -- "$file_path")
                        FILE_NAME_NO_EXT=$(echo "$FILE_NAME" | cut -f 1 -d '.')
                        FILE_CONTENTS=$(base64 -w 0 -i ./api/portal_assets/$FILE_NAME)
                        FILE_CONTENTS_JSON='{"slug": "'"$FILE_NAME_NO_EXT"'","status": "published","title": "'"$FILE_NAME_NO_EXT"'","content": "'"$FILE_CONTENTS"'"}'
                        echo "$FILE_CONTENTS_JSON" > ./docs/"$FILE_NAME_NO_EXT.json"
                    done

                    for file in ./docs/*; do
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
                // Checks if an API Product Version already exists so that we don't create a duplicate each time this is run
                // Create a new API Product Version if the API Product Version ID from the previous script is null
                // Add the OAS to the JSON Payload required by the Konnect Product API Version API and output as a file
                // Upload the prepared OAS JSON Payload to the API Product Version
                sh '''
                    KONNECT_API_PRODUCT_VERSION_ID=$(curl \
                        --request GET \
                        --url ${KONNECT_ADDRESS}/v2/api-products/${API_PRODUCT_ID}/product-versions?filter%5Bname%5D=${API_PRODUCT_VERSION} \
                        --header "Authorization: Bearer ${KONNECT_TOKEN}" \
                        --header "Accept: application/json" | jq -r '.data[0].id')

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

                    base64 -w 0 ./api/oas/spec.yml > oas-encoded.yaml
                    
                    jq --null-input --arg content "$(<oas-encoded.yaml)" '{"name": "oas.yaml", "content": $content}' > product_version_spec.json

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
                // Run the tests defined in our Insomnia Test Suite
                sh '''
                    echo tbc
                 '''
            }
        }

        stage('Deploy to Developer Portal') {
            steps {
                // Publish API Product to the Developer Portal by updating the portal ID field
                sh '''
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