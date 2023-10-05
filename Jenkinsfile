pipeline {
  agent any
  stages {
    stage('install-tools') {
      steps {
        sh '''
                    cd ~ 
                    curl -sL https://github.com/kong/deck/releases/download/v1.25.0/deck_1.25.0_linux_amd64.tar.gz -o deck.tar.gz
                    tar -xf deck.tar.gz -C ~
                    $(pwd)/deck
                    $(pwd)/deck ping                         --konnect-addr $KONNECT_ADDRESS                         --konnect-token $KONNECT_TOKEN                         --konnect-runtime-group-name $KONNECT_CONTROL_PLANE
                    '''
      }
    }

  }
}