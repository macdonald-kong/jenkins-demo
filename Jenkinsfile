pipeline {
    agent any

    parameters {
        string(name: 'KONNECT_CONTROL_PLANE_ID', defaultValue: '1e66084e-0b3c-42e8-9dc8-75e49fe8d4fa', description: 'xxx')
        string(name: 'KONNECT_PORTAL', defaultValue: '4abacaf1-47dc-4c07-83ff-a8801782277e', description: 'xxx')
        string(name: 'API_PRODUCT_NAME', defaultValue: 'Employees-Directory', description: 'xxx')
        string(name: 'API_PRODUCT_DESCRIPTION', defaultValue: 'demo', description: 'xxx')
        string(name: 'API_PRODUCT_VERSION', defaultValue: '1.0.1', description: 'xxx')
        string(name: 'SERVICE_TAGS', defaultValue: 'employees-directory-v1-dev', description: 'xxx')
        choice(name: 'API_PRODUCT_VERSION_STATUS', choices: [ "published", "deprecated", "unpublished" ], description: 'xxx')
        choice(name: 'API_PRODUCT_PUBLISH', choices: [ "true", "false" ], description: 'xxx')
    }

    environment {
        KONNECT_ADDRESS             = credentials('konnect-address')
        KONNECT_CONTROL_PLANE       = credentials('konnect-control-plane')
        KONNECT_TOKEN               = credentials('konnect-token')
    }

    stages {

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
                    echo "Ping Kong Konnect"
                    
                    deck ping \
                        --konnect-addr ${KONNECT_ADDRESS} \
                        --konnect-token ${KONNECT_TOKEN} \
                        --konnect-control-plane-name ${KONNECT_CONTROL_PLANE}
                '''

                sh '''
                    echo "Diff declarative config"
                    
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
                    echo "Backup Existing Kong Configuration"
                    
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
                    
                    deck sync \
                        --state kong.yaml \
                        --konnect-addr ${KONNECT_ADDRESS} \
                        --konnect-token ${KONNECT_TOKEN} \
                        --konnect-control-plane-name ${KONNECT_CONTROL_PLANE} \
                        --select-tag ${SERVICE_TAGS}
                 '''
            }
        }

        stage('Create API Product') {
            steps {

                sh '''
                    echo "Create API Product"
                    
                    API_PRODUCT_ID=$(curl \
                        --url ${KONNECT_ADDRESS}/v2/api-products \
                        --header "Authorization: Bearer ${KONNECT_TOKEN}" \
                        --header 'Content-Type: application/json' \
                        --data '{
                            "name":"'${API_PRODUCT_NAME}'",
                            "description":"'${API_PRODUCT_DESCRIPTION}'"
                        }' | jq -r .id)


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
                            --data @"$file" -v
                    done

                    # Checks if an API Product Version already exists so that we don't create a duplicate each time this is run

                    echo "get-api-product-version-id"

                    KONNECT_API_PRODUCT_VERSION_ID=$(curl \
                        --request GET \
                        --url ${KONNECT_ADDRESS}/v2/api-products/${API_PRODUCT_ID}/product-versions?filter%5Bname%5D=${API_PRODUCT_VERSION} \
                        --header "Authorization: Bearer ${KONNECT_TOKEN}" \
                        --header "Accept: application/json" | jq -r '.data[0].id')

                    # Create a new API Product Version if the API Product Version ID from the previous script is null

                    if [[ "${KONNECT_API_PRODUCT_VERSION_ID}" == "null" ]]; then

                        SERVICE_ID=bebc516a-61ba-54d2-a1f8-84351acf6c4d

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
                                    "runtime_group_id":"'"${KONNECT_CONTROL_PLANE_ID}"'",
                                    "id":"'"${SERVICE_ID}"'"
                                }
                            }' | jq -r '.id')
                    fi

                    # Add the OAS to the JSON Payload required by the Konnect Product API Version API and output as a file

                    echo "Prepare OpenAPI Specification"

                    base64 -w 0 ./api/oas/spec.yml > oas-encoded.yaml
                    
                    jq --null-input --arg content "$(<oas-encoded.yaml)" '{"name": "oas.yaml", "content": $content}' >> product_version_spec.json

                    # Upload the prepared OAS JSON Payload to the API Product Version

                    echo "Upload OpenAPI Specification to API Product Version"

                    curl -v \
                        --url "${KONNECT_ADDRESS}/v2/api-products/${API_PRODUCT_ID}/product-versions/${KONNECT_API_PRODUCT_VERSION_ID}/specifications" \
                        --header "Authorization: Bearer ${KONNECT_TOKEN}" \
                        --header "Content-Type: application/json" \
                        --header "Accept: application/json" \
                        --data @product_version_spec.json

                '''
            }
        }

        stage('Create API Product Version') {
            steps {
                sh '''
                    echo tbc
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
                    --data '{"portal_ids":["${KONNECT_PORTAL}"]}'
                fi

                 '''
            }
        }

    }
}