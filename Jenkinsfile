pipeline {
    agent any

    environment {
        KONNECT_ADDRESS         = credentials('konnect-address')
        KONNECT_CONTROL_PLANE   = credentials('konnect-control-plane')
        KONNECT_TOKEN           = credentials('konnect-token')
    }

    stages {
        stage('checkout-code') {
            steps {
                checkout scmGit(branches: [[name: '*/main']], extensions: [], userRemoteConfigs: [[url: 'https://github.com/macdonald-kong/jenkins-demo']])
                sh '''
                    echo "install yq"
                    curl -o yq_linux_amd64 https://github.com/mikefarah/yq/releases/download/v4.26.1/yq_linux_amd64
                    ./yq_linux_amd64 -V

                    echo "install jq"
                    curl  https://github.com/jqlang/jq/releases/download/jq-1.7/jq-1.7.tar.gz -o jq.tar.gz
                    tar -xf jq.tar.gz -C .
                    jq -V

                    echo "install deck"
                    curl -sL https://github.com/kong/deck/releases/download/v1.25.0/deck_1.25.0_linux_amd64.tar.gz -o deck.tar.gz
                    tar -xf deck.tar.gz -C .
                    deck version

                    echo "install inso"
                    curl -sL https://github.com/Kong/insomnia/releases/download/lib%408.2.0/inso-linux-8.2.0.tar.xz -o inso.tar.xz
                    tar -xf inso.tar.xz -C .
                    inso -v

                    echo "export OpenAPI Spec"
                    # inso export spec $(./yq_linux_amd64 '.name' $(echo -n ./.insomnia/Workspace/*)) > ./api/oas.yaml

                    echo "Set Variables"
                    KONNECT_PORTAL=$(echo 4abacaf1-47dc-4c07-83ff-a8801782277e)
                    KONNECT_RUNTIME_GROUP_NAME=$(./yq_linux_amd64 '.runtimeGroup' ./config.yaml)
                    KONNECT_REGION=$(./yq_linux_amd64 '.region' ./config.yaml)
                    API_PRODUCT_NAME=$(./yq_linux_amd64 '.apiProductName' ./config.yaml)
                    API_PRODUCT_DESCRIPTION=$(./yq_linux_amd64 .info.description ./api/oas.yaml)
                    API_PRODUCT_VERSION=$(./yq_linux_amd64 '.info.version' ./api/oas.yaml)
                    API_PRODUCT_VERSION_STATUS=$(./yq_linux_amd64 '.versionStatus' ./config.yaml)
                    API_PRODUCT_PUBLISH=$(./yq_linux_amd64 '.publishToPortal' ./config.yaml)
                    SERVICE_TAGS=$(./yq_linux_amd64 '.info.title' ./api/oas.yaml)"

                    echo "URL Encode Variables"
                    API_PRODUCT_NAME_ENCODED=$(echo ${PRODUCT_NAME} | sed 's/ /%20/g')
                    KONNECT_RUNTIME_GROUP_NAME_ENCODED=$(echo ${KONNECT_RUNTIME_GROUP_NAME} | sed 's/ /%20/g')

                    echo "Concat API Product Version Variable"
                    API_PRODUCT_VERSION=$(echo ${API_PRODUCT_VERSION}-${KONNECT_RUNTIME_GROUP_NAME_ENCODED})

                    echo "Get Konnect Runtime Group ID"
                    echo "KONNECT_RUNTIME_GROUP_ID=$(curl \
                        --url "${KONNECT_ADDRESS}/v2/runtime-groups?filter%5Bname%5D=${KONNECT_RUNTIME_GROUP_NAME_ENCODED}" \
                        --header "accept: */*"  \
                        --header "Authorization: Bearer ${KONNECT_TOKEN}" | jq -r '.data[0].id')

                    echo "Lint OpenAPI Spec"
                    inso lint spec ./api/oas.yaml

                    echo "Generate Kong declarative configuration from Spec"
                    deck file openapi2kong \
                        --spec ./api/oas.yaml \
                        --format yaml \
                        --select-tag ${SERVICE_TAGS} \
                        --output-file ./kong-generated.yaml

                    echo "Ping Kong Konnect"
                    ./deck ping \
                        --konnect-addr ${KONNECT_ADDRESS} \
                        --konnect-token ${KONNECT_TOKEN} \
                        --konnect-runtime-group-name ${KONNECT_CONTROL_PLANE}

                    echo "Merge Kong Configuration with Plugins"
                    deck file merge ./kong-generated.yaml ./api/plugins/* -o kong.yaml

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
