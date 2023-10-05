pipeline {
    agent any

    environment {
        KONNECT_ADDRESS             = credentials('konnect-address')
        KONNECT_CONTROL_PLANE       = credentials('konnect-control-plane')
        KONNECT_TOKEN               = credentials('konnect-token')
        KONNECT_PORTAL              = "4abacaf1-47dc-4c07-83ff-a8801782277e"
        KONNECT_RUNTIME_GROUP_NAME  = "hr-dev"
        KONNECT_RUNTIME_GROUP_ID    = "1e66084e-0b3c-42e8-9dc8-75e49fe8d4fa"
        API_PRODUCT_NAME            = "Employees Directory"
        API_PRODUCT_DESCRIPTION     = "This is a sample Employee Directory Server based on the OpenAPI 3.0 specification."
        API_PRODUCT_VERSION         = "1.0.1"
        API_PRODUCT_VERSION_STATUS  = "published"
        API_PRODUCT_PUBLISH         = "true"
        SERVICE_TAGS                = "employees-directory-v1-dev"
    }

    stages {
        stage('checkout-code') {
            steps {
                checkout scmGit(branches: [[name: '*/main']], extensions: [], userRemoteConfigs: [[url: 'https://github.com/macdonald-kong/jenkins-demo']])
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
                    API_PRODUCT_NAME_ENCODED=$(echo ${PRODUCT_NAME} | sed 's/ /%20/g')
                    KONNECT_RUNTIME_GROUP_NAME_ENCODED=$(echo ${KONNECT_RUNTIME_GROUP_NAME} | sed 's/ /%20/g')

                    echo "Concat API Product Version Variable"
                    API_PRODUCT_VERSION=$(echo ${API_PRODUCT_VERSION}-${KONNECT_RUNTIME_GROUP_NAME_ENCODED})

                    echo "Generate Kong declarative configuration from Spec"
                    ./deck file openapi2kong \
                        --spec ./api/oas/spec.yml \
                        --format yaml \
                        --select-tag ${SERVICE_TAGS} \
                        --output-file kong-generated.yaml

                    ls
                    cat ./kong-generated.yaml

                    echo "Ping Kong Konnect"
                    ./deck ping \
                        --konnect-addr ${KONNECT_ADDRESS} \
                        --konnect-token ${KONNECT_TOKEN} \
                        --konnect-runtime-group-name ${KONNECT_CONTROL_PLANE}

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
    }
}
