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
                    echo install-tools
                    curl -sL https://github.com/kong/deck/releases/download/v1.25.0/deck_1.25.0_linux_amd64.tar.gz -o deck.tar.gz
                    tar -xf deck.tar.gz -C $(pwd)
                    ./deck
                    ./deck ping \
                        --konnect-addr ${KONNECT_ADDRESS} \
                        --konnect-token ${KONNECT_TOKEN} \
                        --konnect-runtime-group-name ${KONNECT_CONTROL_PLANE}
                    $(pwd)/deck validate \
                        --state /var/jenkins_home/workspace/tst/kong.yaml
                    $(pwd)/deck diff \
                        --state /var/jenkins_home/workspace/tst/kong.yaml \
                        --konnect-addr ${KONNECT_ADDRESS} \
                        --konnect-token ${KONNECT_TOKEN} \
                        --konnect-runtime-group-name ${KONNECT_CONTROL_PLANE} \
                        --select-tag "hello"
                '''
            }
        }
    }
}
