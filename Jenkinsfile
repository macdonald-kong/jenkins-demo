pipeline {
  agent any
  stages {
    stage('demo') {
      steps {
        sh 'curl -sL https://github.com/kong/deck/releases/download/v1.25.0/deck_1.25.0_linux_amd64.tar.gz -o deck.tar.gz'
        sh 'tar -xf deck.tar.gz -C /tmp'
        sh 'cp /tmp/deck /usr/local/bin/'
      }
    }

  }
}