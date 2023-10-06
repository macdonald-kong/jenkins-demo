pipeline {
    agent any

    parameters {
        string(name: 'KONNECT_CONTROL_PLANE_ID', defaultValue: '1e66084e-0b3c-42e8-9dc8-75e49fe8d4fa', description: 'xxx')
        string(name: 'KONNECT_PORTAL', defaultValue: '4abacaf1-47dc-4c07-83ff-a8801782277e', description: 'xxx')
        string(name: 'API_PRODUCT_NAME', defaultValue: 'Employees Directory', description: 'xxx')
        string(name: 'API_PRODUCT_DESCRIPTION', defaultValue: 'This is a sample Employee Directory Server based on the OpenAPI 3.0 specification.', description: 'xxx')
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

        stage('Install Dependencies') {
            steps {
                sh '''
                    echo "install yq"
                    curl -o yq https://github.com/mikefarah/yq/releases/download/v4.26.1/yq_linux_amd64 && chmod +x ./yq
                    ./yq -V
                '''

                sh '''
                    echo "install jq"
                    curl -o jq https://github.com/jqlang/jq/releases/download/jq-1.7/jq-linux-amd64 && chmod +x ./jq
                    ./jq -V
                '''
                
                sh '''
                    echo "install deck"
                    curl -sL https://github.com/kong/deck/releases/download/v1.25.0/deck_1.25.0_linux_amd64.tar.gz -o deck.tar.gz
                    tar -xf deck.tar.gz -C .
                    ./deck version
                '''

                sh '''
                    echo "URL Encode Variables"
                    API_PRODUCT_NAME_ENCODED=$(echo ${API_PRODUCT_NAME} | sed 's/ /%20/g')
                    KONNECT_CONTROL_PLANE_NAME_ENCODED=$(echo ${KONNECT_CONTROL_PLANE} | sed 's/ /%20/g')

                    echo "Concat API Product Version Variable"
                    API_PRODUCT_VERSION=$(echo ${API_PRODUCT_VERSION}-${KONNECT_CONTROL_PLANE_NAME_ENCODED})
                '''

                sh '''
                    echo "Ping Kong Konnect"
                    ./deck ping \
                        --konnect-addr ${KONNECT_ADDRESS} \
                        --konnect-token ${KONNECT_TOKEN} \
                        --konnect-runtime-group-name ${KONNECT_CONTROL_PLANE}
                '''
            }
        }

        stage('Build Kong Declarative Configuration') {
            steps {
                sh '''
                    echo "Generate Kong declarative configuration from Spec"
                    ./deck file openapi2kong \
                        --spec ./api/oas/spec.yml \
                        --format yaml \
                        --select-tag ${SERVICE_TAGS} \
                        --output-file kong-generated.yaml
                '''

                sh '''
                    echo "Merge Kong Configuration with Plugins"
                    ./deck file merge ./kong-generated.yaml ./api/plugins/* -o kong.yaml
                '''

                sh '''
                    echo "Validate Kong declarative configuration"
                    ./deck validate \
                        --state kong.yaml
                    ./deck file merge ./kong-generated.yaml ./api/plugins/* -o kong.yaml
                '''

                sh '''
                    echo "Diff declarative config"
                    ./deck diff \
                        --state kong.yaml \
                        --konnect-addr ${KONNECT_ADDRESS} \
                        --konnect-token ${KONNECT_TOKEN} \
                        --konnect-runtime-group-name ${KONNECT_CONTROL_PLANE} \
                        --select-tag ${SERVICE_TAGS}
                 '''
            }
        }

        stage('Backup Existing Configuration') {
            steps {
                sh '''
                    echo "Backup Existing Kong Configuration"
                    ./deck dump \
                        --konnect-addr ${KONNECT_ADDRESS} \
                        --konnect-token ${KONNECT_TOKEN} \
                        --konnect-runtime-group-name ${KONNECT_CONTROL_PLANE} \
                        --output-file kong-backup.yaml \
                        --yes
                 '''
            }
        }

        stage('Deploy Kong Declarative Configuration') {
            steps {
                sh '''
                    ./deck sync \
                        --state kong.yaml \
                        --konnect-addr ${KONNECT_ADDRESS} \
                        --konnect-token ${KONNECT_TOKEN} \
                        --konnect-runtime-group-name ${KONNECT_CONTROL_PLANE} \
                        --select-tag ${SERVICE_TAGS}
                 '''
            }
        }

        stage('Create API Product') {
            steps {
                sh '''
                    echo "Get API Product ID if it already exists"
                    API_PRODUCT_ID=$(curl \
                        --request GET \
                        --url "${KONNECT_ADDRESS}/v2/api-products?filter%5Bname%5D=${API_PRODUCT_NAME_ENCODED}" \
                        --header "Authorization: Bearer ${KONNECT_TOKEN}" \
                        --header "Accept: application/json" | jq -r '.data[0].id')
                '''

                sh '''
                    echo "Create API Product"
                    echo API_PRODUCT_ID: ${API_PRODUCT_ID}
                    if [[ "${API_PRODUCT_ID}" == "null" ]]; then
                        API_PRODUCT_ID=$(curl \
                            --url ${KONNECT_ADDRESS}/v2/api-products \
                            --header "Authorization: Bearer ${KONNECT_TOKEN}" \
                            --header 'Content-Type: application/json' \
                            --data '{
                                "name":"${API_PRODUCT_NAME}",
                                "description":"${API_PRODUCT_DESCRIPTION}"
                            }' | jq -r .id)
                    fi
                '''

                sh '''
                    echo "Prepare Static Documentation"
                    mkdir docs
                    for entry in "./api/portal_assets"/*
                    do
                        echo "{\"slug\":\"$(echo "$entry" | sed 's#.*/([^/]*).md#1#')\",\"status\":\"published\",\"title\":\"$(echo "$entry" | sed 's#.*/([^/]*).md#1#')\",\"content\":\"$(base64 -i ./api/portal_assets/${entry##*/})\"}" >> ./docs/$(echo "$entry" | sed 's#.*/([^/]*).md#1#').json
                    done
                    ls ./api/portal_assets
                '''

                sh '''
                    echo "Upload Static Documentation"
                    for entry in "./docs"/*
                    do
                        curl -X POST ${KONNECT_ADDRESS}/v2/api-products/${API_PRODUCT_ID}/documents \
                            --header "Authorization: Bearer ${KONNECT_TOKEN}" \
                            --header "Content-Type: application/json" \
                            -d @$entry
                    done
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
                    echo tbc
                 '''
            }
        }

    }
}