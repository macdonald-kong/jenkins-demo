pipeline {
  agent any
  stages {
    stage('demo') {
      steps {
        sh '''curl -sL https://github.com/kong/deck/releases/download/v1.25.0/deck_1.25.0_linux_amd64.tar.gz -o deck.tar.gz
tar -xf deck.tar.gz -C /tmp
cp /tmp/deck /usr/local/bin/'''
        sh '''curl -sL https://github.com/Kong/insomnia/releases/download/lib%403.18.0/inso-linux-3.18.0.tar.xz -o inso.tar.xz
tar -xf inso.tar.xz -C /tmp
cp /tmp/inso /usr/local/bin/'''
      }
    }

  }
}