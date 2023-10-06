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

                    echo "install jq"
                    curl -o jq https://github.com/jqlang/jq/releases/download/jq-1.7/jq-linux-amd64 && chmod +x ./jq
                    ./jq -V

                    echo "install deck"
                    curl -sL https://github.com/kong/deck/releases/download/v1.25.0/deck_1.25.0_linux_amd64.tar.gz -o deck.tar.gz
                    tar -xf deck.tar.gz -C .
                    ./deck version

                    echo "URL Encode Variables"
                    API_PRODUCT_NAME_ENCODED=$(echo ${API_PRODUCT_NAME} | sed 's/ /%20/g')
                    KONNECT_CONTROL_PLANE_NAME_ENCODED=$(echo ${KONNECT_CONTROL_PLANE} | sed 's/ /%20/g')

                    echo "Concat API Product Version Variable"
                    API_PRODUCT_VERSION=$(echo ${API_PRODUCT_VERSION}-${KONNECT_CONTROL_PLANE_NAME_ENCODED})

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

                    echo "Merge Kong Configuration with Plugins"
                    ./deck file merge ./kong-generated.yaml ./api/plugins/* -o kong.yaml

                    echo "Validate Kong declarative configuration"
                    ./deck validate \
                        --state kong.yaml

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
                        --output-file kong-backup.yaml
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

    }
}