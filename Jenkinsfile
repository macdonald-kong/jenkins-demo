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
                    echo "install deck"
                    curl -sL https://github.com/kong/deck/releases/download/v1.25.0/deck_1.25.0_linux_amd64.tar.gz -o deck.tar.gz
                    tar -xf deck.tar.gz -C .

                    echo "install inso"
                    curl -sL https://github.com/Kong/insomnia/releases/download/lib%403.18.0/inso-linux-3.18.0.tar.xz -o inso.tar.xz
                    tar -xf inso.tar.xz -C /tmp
                    sudo cp /tmp/inso /usr/local/bin/

                    echo "export OpenAPI Spec"
                    inso export spec $(yq '.name' $(echo -n ./.insomnia/Workspace/*)) > ./api/oas.yaml

                    echo "Set Variables"
                    KONNECT_PORTAL=$(echo 4abacaf1-47dc-4c07-83ff-a8801782277e)
                    KONNECT_RUNTIME_GROUP_NAME=$(yq .runtimeGroup ./config.yaml)
                    KONNECT_REGION=$(yq .region ./config.yaml)
                    API_PRODUCT_NAME=$(yq .apiProductName ./config.yaml)
                    API_PRODUCT_DESCRIPTION=$(yq .info.description ./api/oas.yaml)
                    API_PRODUCT_VERSION=$(yq .info.version ./api/oas.yaml)
                    API_PRODUCT_VERSION_STATUS=$(yq .versionStatus ./config.yaml)
                    API_PRODUCT_PUBLISH=$(yq .publishToPortal ./config.yaml)
                    SERVICE_TAGS=$(yq '.info.title' ./api/oas.yaml)"

                    echo "URL Encode Variables"
                    API_PRODUCT_NAME_ENCODED=$(echo ${{ env.API_PRODUCT_NAME }} | sed 's/ /%20/g')
                    KONNECT_RUNTIME_GROUP_NAME_ENCODED=$(echo ${{ env.KONNECT_RUNTIME_GROUP_NAME }} | sed 's/ /%20/g')

                    echo "Concat API Product Version Variable"
                    API_PRODUCT_VERSION=$(echo ${{ env.API_PRODUCT_VERSION }}-${{ env.KONNECT_RUNTIME_GROUP_NAME_ENCODED }})

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
