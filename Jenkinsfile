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
        KONNECT_TOKEN = credentials('konnect-token')
    }

    parameters {
        string(name: 'KONNECT_ADDRESS', defaultValue: 'https://us.api.konghq.com', description: 'xxx')

        string(name: 'KONNECT_CONTROL_PLANE_NAME', defaultValue: 'development', description: 'xxx')
        string(name: 'KONNECT_CONTROL_PLANE_ID', defaultValue: '')
        string(name: 'KONNECT_CONTROL_PLANE_NAME_CLEAN', defaultValue: '')

        string(name: 'KONNECT_PORTAL', defaultValue: '19276d90-1a79-4001-ae7d-e4a5bf05fe76', description: 'xxx')

        string(name: 'API_PRODUCT_ID', defaultValue: '')
        string(name: 'API_PRODUCT_NAME', defaultValue: '', description: 'xxx')
        string(name: 'API_PRODUCT_NAME_ENCODED', defaultValue: '', description: 'xxx')
        string(name: 'API_PRODUCT_NAME_CLEAN', defaultValue: '', description: 'xxx')

        string(name: 'API_PRODUCT_DESCRIPTION', defaultValue: '', description: 'xxx')
        choice(name: 'API_PRODUCT_PUBLISH', choices: [ "true", "false" ], description: 'xxx')

        string(name: 'API_PRODUCT_VERSION_ID', defaultValue: '')
        string(name: 'API_PRODUCT_VERSION', defaultValue: '', description: 'xxx')
        choice(name: 'API_PRODUCT_VERSION_STATUS', choices: [ "published", "deprecated", "unpublished" ], description: 'xxx')

        string(name: 'GATEWAY_SERVICE_ID', defaultValue: '')
        string(name: 'GATEWAY_SERVICE_TAGS', defaultValue: '', description: 'xxx')
        string(name: 'GATEWAY_URL', defaultValue: 'https://a7a34e584919344cd8e84746d9531009-200741905.eu-west-2.elb.amazonaws.com:8443')

        string(name: 'DECK_GATEWAY_SERVICE_NAME', defaultValue: '')
    }

    stages {

        stage('Check Prerequisites') {
            steps {

                // Check that jq has been installed and print version
                sh 'jq -V'

                // Check that yq has been installed and print version
                sh 'yq --version'

                // Check that deck has been installed and print version
                sh 'deck version'

                // Check Inso CLI is installed and print version
                sh ' inso -v'

                // Ping Kong Konnect to check connectivity
                sh '''
                    deck ping \
                        --konnect-addr ${KONNECT_ADDRESS} \
                        --konnect-token ${KONNECT_TOKEN} \
                        --konnect-control-plane-name ${KONNECT_CONTROL_PLANE_NAME}
                '''
            }
        }

        stage('Set Variables') {
            steps {
                script {

                    // Extract the API Product name from the title of the OAS
                    TMP_API_PRODUCT_NAME = sh (script: 'yq .info.title ./api/spec.yaml -r', returnStdout: true).trim()
                    env.API_PRODUCT_NAME = TMP_API_PRODUCT_NAME
                    echo "API Product name from OAS: $TMP_API_PRODUCT_NAME"

                    // The API Product name might include spaces that we are changing to dashes.
                    TMP_API_PRODUCT_NAME_CLEAN = sh (script: "echo ${TMP_API_PRODUCT_NAME} | sed 's/ /-/g'", returnStdout: true).trim()
                    TMP_API_PRODUCT_NAME_CLEAN = TMP_API_PRODUCT_NAME_CLEAN.toLowerCase()
                    env.API_PRODUCT_NAME_CLEAN = TMP_API_PRODUCT_NAME_CLEAN
                    echo "Cleaned API Product name : $API_PRODUCT_NAME_CLEAN"

                    // The API Product name might include spaces that we are encoding - this is important as we need to use this for search.
                    TMP_API_PRODUCT_NAME_ENCODED = sh (script: "echo ${TMP_API_PRODUCT_NAME} | sed 's/ /%20/g'", returnStdout: true).trim()
                    env.API_PRODUCT_NAME_ENCODED = TMP_API_PRODUCT_NAME_ENCODED
                    echo "Encoded API Product name: $API_PRODUCT_NAME_ENCODED"

                    // The Konnect Control Plane name might include spaces that we are changing to dashes.
                    TMP_KONNECT_CONTROL_PLANE_NAME_CLEAN = sh (script: "echo ${KONNECT_CONTROL_PLANE_NAME} | sed 's/ /-/g'", returnStdout: true).trim()
                    env.KONNECT_CONTROL_PLANE_NAME_CLEAN = TMP_KONNECT_CONTROL_PLANE_NAME_CLEAN
                    echo "Cleaned Konnect Control Plane name : $TMP_KONNECT_CONTROL_PLANE_NAME_CLEAN"

                    // Use the Konnect Control Plane Name to search for the ID using the Konnect Control Plane API
                    TMP_KONNECT_CONTROL_PLANE_ID = sh (script: 'curl --url "${KONNECT_ADDRESS}/v2/control-planes?filter%5Bname%5D=${KONNECT_CONTROL_PLANE_NAME_CLEAN}" --header "accept: */*" --header "Authorization: Bearer ${KONNECT_TOKEN}" | jq -r \'.data[0].id\'', returnStdout: true).trim()
                    env.KONNECT_CONTROL_PLANE_ID = TMP_KONNECT_CONTROL_PLANE_ID
                    echo "Konnect Control Plane ID: $TMP_KONNECT_CONTROL_PLANE_ID"

                    // Extract API Product Description, Version and Gateway Service Tags from the OAS
                    TMP_API_PRODUCT_DESCRIPTION = sh (script: 'yq .info.description ./api/spec.yaml -r', returnStdout: true).trim()
                    env.API_PRODUCT_DESCRIPTION = TMP_API_PRODUCT_DESCRIPTION
                    echo "API Product Description ID: $TMP_API_PRODUCT_DESCRIPTION"

                    // The API Product Version name will not be unique if just based on what we extract from the OAS - we need to add the Control Plane Name to this
                    TMP_API_PRODUCT_VERSION_RAW = sh (script: 'yq .info.version ./api/spec.yaml -r', returnStdout: true).trim()
                    echo "API Product Version ID Raw: $TMP_API_PRODUCT_VERSION_RAW"

                    TMP_API_PRODUCT_VERSION = sh (script: "echo $TMP_API_PRODUCT_VERSION_RAW-$KONNECT_CONTROL_PLANE_NAME_CLEAN", returnStdout: true).trim()
                    env.API_PRODUCT_VERSION = TMP_API_PRODUCT_VERSION
                    echo "API Product Version ID: $TMP_API_PRODUCT_VERSION"

                    // xxx
                    TMP_DECK_GATEWAY_SERVICE_NAME = sh (script: "echo $TMP_API_PRODUCT_NAME_CLEAN-$TMP_API_PRODUCT_VERSION_RAW", returnStdout: true).trim()
                    env.DECK_GATEWAY_SERVICE_NAME = TMP_DECK_GATEWAY_SERVICE_NAME
                    echo "Gateway Service Name: $TMP_DECK_GATEWAY_SERVICE_NAME"

                    // xxx
                    TMP_GATEWAY_SERVICE_TAGS = sh (script: "echo $TMP_API_PRODUCT_VERSION-$API_PRODUCT_NAME_CLEAN", returnStdout: true).trim()
                    env.GATEWAY_SERVICE_TAGS = TMP_GATEWAY_SERVICE_TAGS
                    echo "Gateway Service Tags: $TMP_GATEWAY_SERVICE_TAGS"
                    }
            }
        }

        stage('Lint OAS') {
            steps {
                // Lint OAS with Inso CLI
                sh 'inso lint spec ./api/spec.yaml'
            }
        }

        stage('Build Kong Declarative Configuration') {
            steps {
                // Generate Kong declarative configuration from Spec
                sh '''
                    deck file openapi2kong \
                        --spec ./api/spec.yaml \
                        --format yaml \
                        --select-tag ${GATEWAY_SERVICE_TAGS} \
                        --output-file kong-generated.yaml
                '''

                // Merge Kong Configuration with Plugins
                sh 'deck file merge ./kong-generated.yaml ./api/plugins/* -o kong.yaml'

                // Update Service Name with Version
                sh "yq --in-place '.services[0].name = \"$DECK_GATEWAY_SERVICE_NAME\"' ./kong.yaml -y"

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
                        --konnect-control-plane-name ${KONNECT_CONTROL_PLANE_NAME} \
                        --select-tag ${GATEWAY_SERVICE_TAGS}
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
                        --konnect-control-plane-name ${KONNECT_CONTROL_PLANE_NAME} \
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
                        --konnect-control-plane-name ${KONNECT_CONTROL_PLANE_NAME} \
                        --select-tag ${GATEWAY_SERVICE_TAGS}
                 '''
            }
        }
        
        stage('Get Gateway Service ID') {
            steps {
                script {
                    // Set a Variable containing the Service ID of the Service that we deployed - we need this to link the API Product to a Kong Service
                    TMP_GATEWAY_SERVICE_ID =  sh(script: '''
                        curl --url "${KONNECT_ADDRESS}/v2/control-planes/${KONNECT_CONTROL_PLANE_ID}/core-entities/services?tags=${GATEWAY_SERVICE_TAGS}" \
                        --header 'accept: application/json' \
                        --header "Authorization: Bearer ${KONNECT_TOKEN}" | jq -r \'.data[0].id\'
                        ''', returnStdout: true).trim()
                    
                    env.GATEWAY_SERVICE_ID = TMP_GATEWAY_SERVICE_ID

                    echo "Gateway Service ID: $TMP_GATEWAY_SERVICE_ID"
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
            }
            steps {
                // Delete the current API Product documentation so that we can upload the new ones with any updates
                // This is very inneficient - will improve later
                sh '''
                    DOCUMENTS_JSON=$(curl --url ${KONNECT_ADDRESS}/v2/api-products/${API_PRODUCT_ID}/documents \
                        --header "Authorization: Bearer ${KONNECT_TOKEN}" \
                        --header "Content-Type: application/json")

                    echo "Currently available documentation: $DOCUMENTS_JSON"

                    # Extract document IDs and send DELETE requests
                    ids=$(echo $DOCUMENTS_JSON | jq -r '.data[].id')

                    for id in $ids; do
                        curl -X DELETE --url $KONNECT_ADDRESS/v2/api-products/$API_PRODUCT_ID/documents/$id \
                            --header "Authorization: Bearer ${KONNECT_TOKEN}" 
                    done
                '''
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

        stage('Check if API Product Version Exists') {
            steps {
                script {
                    // Checks if an API Product Version already exists so that we don't create a duplicate each time this is run
                    TMP_API_PRODUCT_VERSION_ID = sh(script: '''
                        curl --request GET \
                            --url ${KONNECT_ADDRESS}/v2/api-products/${API_PRODUCT_ID}/product-versions?filter%5Bname%5D=${API_PRODUCT_VERSION} \
                            --header "Authorization: Bearer ${KONNECT_TOKEN}" \
                            --header "Accept: application/json" \
                            | jq -r '.data[0].id'
                    ''', returnStdout: true).trim()

                    env.API_PRODUCT_VERSION_ID = TMP_API_PRODUCT_VERSION_ID

                    echo "API Product Version ID: $TMP_API_PRODUCT_VERSION_ID"
                }
            }
        }

        stage('Delete API Product Version OAS') {
            when {
                expression { env.API_PRODUCT_VERSION_ID != 'null' }
            }
            steps {
                // Delete the current Product API Version OAS so that we can upload the new one with any updates
                // This is very inneficient - will improve later
                sh '''
                    # Fetch OAS JSON from Kong Konnect API
                    OAS_ID=$(curl --url "${KONNECT_ADDRESS}/v2/api-products/${API_PRODUCT_ID}/product-versions/${API_PRODUCT_VERSION_ID}/specifications" \
                        --header "Authorization: Bearer ${KONNECT_TOKEN}" \
                        --header "Content-Type: application/json" | jq -r '.data[].id')

                    curl -X DELETE --url "${KONNECT_ADDRESS}/v2/api-products/${API_PRODUCT_ID}/product-versions/${API_PRODUCT_VERSION_ID}/specifications/${OAS_ID}" \
                        --header "Authorization: Bearer ${KONNECT_TOKEN}"
                '''
                }
            }

        stage('Create API Product Version') {
            when {
                expression { env.API_PRODUCT_VERSION_ID == 'null' }
            }
            steps {
                // Create a new API Product Version if the API Product Version ID from the previous script is null
                script {
                    TMP_API_PRODUCT_VERSION_ID = sh(script: '''
                        curl -X POST \
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
                                    "id":"'"${GATEWAY_SERVICE_ID}"'"
                                }
                            }' \
                        | jq -r '.id'
                    ''', returnStdout: true).trim()

                    env.API_PRODUCT_VERSION_ID = TMP_API_PRODUCT_VERSION_ID

                    echo "API Product Version ID: $TMP_API_PRODUCT_VERSION_ID"
                }
            }
        }

        stage('Upload OAS to API Product Version') {
            steps {

                // Update the specification with the correct Kong Gateway URL location instead of pointing to the backend service.
                sh "yq -i '.servers[0].url = \"$GATEWAY_URL\"' ./api/spec.yaml -y"

                // Add the OAS to the JSON Payload required by the Konnect Product API Version API and output as a file
                sh '''
                    base64 -w 0 ./api/spec.yaml > oas-encoded.yaml
                    jq --null-input --arg content "$(cat oas-encoded.yaml)" '{"name": "oas.yaml", "content": $content}' > product_version_spec.json

                '''

                // Upload the prepared OAS JSON Payload to the API Product Version
                sh '''
                    curl \
                        --url "${KONNECT_ADDRESS}/v2/api-products/${API_PRODUCT_ID}/product-versions/${API_PRODUCT_VERSION_ID}/specifications" \
                        --header "Authorization: Bearer ${KONNECT_TOKEN}" \
                        --header "Content-Type: application/json" \
                        --header "Accept: application/json" \
                        --data @product_version_spec.json
                '''
            }
        }
        
        stage('Run Tests') {
            steps {
                // Test Deployed Service with Inso CLI
                sh 'inso run test uts_7e3ccb -e env_85c4a08968 --ci -w .'
            }
        }
        
        stage('Deploy to Developer Portal') {
            when {
                expression { env.API_PRODUCT_PUBLISH.toBoolean() == true }
            }
            steps {
                // Publish API Product to the Developer Portal by updating the portal ID field
                sh '''
                    curl --request PATCH \
                    --url "${KONNECT_ADDRESS}/v2/api-products/${API_PRODUCT_ID}" \
                    --header "Authorization: Bearer ${KONNECT_TOKEN}" \
                    --header 'Content-Type: application/json' \
                    --header 'accept: application/json' \
                    --data '{"portal_ids":["'"$KONNECT_PORTAL"'"]}'
                '''
            }
        }
    }
    
    post {
        always {
            // Archive our latest Kong declarative configuration
            archiveArtifacts artifacts: 'kong.yaml', fingerprint: true
            // Archive our backup artifact
            archiveArtifacts artifacts: 'kong-backup.yaml', fingerprint: true
            // Clean up the workspace
            // deleteDir()
        }
    }
}
