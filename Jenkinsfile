pipeline {
  agent {
    node {
      label 'arkyco-build-agent'
    }
  }
  stages {
    stage ('Clone') {
      steps {
        checkout([
          $class: 'GitSCM',
          branches: scm.branches,
          extensions: scm.extensions + [[$class: 'CleanBeforeCheckout']],
          userRemoteConfigs: scm.userRemoteConfigs
        ])
      }
    }
    stage ('Plan') {
      steps {
        ansiColor('xterm') {
         script {
          def tfinit = sh script: 'terraform init', returnStdout: true
          def tfplan = sh returnStdout: true, script: "terraform plan -no-color -var-file=terraform.tfvars 2>&1"
          println tfplan;
          env.TF_PLAN = tfplan
         }
      }
    }
  }
}
