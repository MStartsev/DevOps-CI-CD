// Jenkinsfile - CI/CD pipeline
// Stages:
//   1. Checkout        - clone source repo (branch: lesson-db-module)
//   2. Build & Push    - build Docker image with Kaniko, push to ECR
//   3. Update Helm     - update image.tag in charts/django-app/values.yaml
//   4. Push to Git     - commit and push to main => Argo CD detects and syncs


pipeline {
  agent {
    kubernetes {
      label 'kaniko'
      yaml """
apiVersion: v1
kind: Pod
spec:
  serviceAccountName: kaniko
  containers:
    - name: kaniko
      image: gcr.io/kaniko-project/executor:debug
      command: [sleep]
      args: ["99d"]
    - name: git
      image: alpine/git:latest
      command: [sleep]
      args: ["99d"]
  volumes: []
"""
    }
  }

  environment {
    AWS_REGION  = "us-west-2"
    ECR_REPO    = "585019520715.dkr.ecr.us-west-2.amazonaws.com/devops_project"
    GIT_REPO    = "https://github.com/MStartsev/DevOps-CI-CD.git"
    SRC_BRANCH  = "lesson-db-module"
    DEPLOY_BRANCH = "main"
    VALUES_FILE = "charts/django-app/values.yaml"
    IMAGE_TAG   = "${BUILD_NUMBER}"
  }

  stages {

    stage('Checkout') {
      steps {
        container('git') {
          git branch: "${SRC_BRANCH}",
              url: "${GIT_REPO}",
              credentialsId: 'github-credentials'
        }
      }
    }

    stage('Build & Push to ECR') {
      steps {
        container('kaniko') {
          sh """
            /kaniko/executor \\
              --context=dir:///${WORKSPACE}/django-src \\
              --dockerfile=/${WORKSPACE}/django-src/Dockerfile \\
              --destination=${ECR_REPO}:${IMAGE_TAG} \\
              --destination=${ECR_REPO}:latest \\
              --cache=true
          """
        }
      }
    }

    stage('Update Helm values.yaml & Push to main') {
    steps {
        container('git') {
            withCredentials([usernamePassword(
                credentialsId: 'github-credentials',
                usernameVariable: 'GIT_USER',
                passwordVariable: 'GIT_TOKEN'
            )]) {
                sh """
                    git config --global user.email "jenkins@ci.local"
                    git config --global user.name "Jenkins CI"

                    git clone https://${GIT_USER}:${GIT_TOKEN}@github.com/MStartsev/DevOps-CI-CD.git /tmp/repo
                    cd /tmp/repo

                    # Переключаємось на DEPLOY_BRANCH
                    git fetch origin ${DEPLOY_BRANCH} || true
                    git checkout -B ${DEPLOY_BRANCH} origin/${DEPLOY_BRANCH} 2>/dev/null || git checkout -b ${DEPLOY_BRANCH}

                    # Копіюємо ВЕСЬ charts/ з lesson-db-module
                    git checkout origin/${SRC_BRANCH} -- charts/

                    # Оновлюємо тільки тег у values.yaml
                    sed -i "s/^  tag:.*/  tag: \\"${IMAGE_TAG}\\"/" ${VALUES_FILE}

                    git add charts/
                    git diff --cached --quiet && echo "Nothing to commit" && exit 0
                    git commit -m "ci: update image tag to ${IMAGE_TAG} [skip ci]"
                    git push https://${GIT_USER}:${GIT_TOKEN}@github.com/MStartsev/DevOps-CI-CD.git ${DEPLOY_BRANCH}
                """
            }
        }
    }
}

  }

  post {
    success {
      echo "Pipeline finished. Argo CD watches 'main' and will sync automatically."
    }
    failure {
      echo "Pipeline failed. Check logs above."
    }
  }
}
