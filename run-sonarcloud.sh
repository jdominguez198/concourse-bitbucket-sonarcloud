#!/usr/bin/env bash

: "${INPUT_FOLDER:?}"
: "${REPOSITORY_EXCLUSIONS:?}"
: "${REPOSITORY_SOURCES:?}"
: "${SONAR_PROJECT_KEY:?}"
: "${SONAR_PROJECT_NAME:?}"
: "${SONAR_PROJECT_ORGANIZATION:?}"
: "${SONAR_TOKEN:?}"

echo ">>>> Showing files from directory..."
ls -lah $INPUT_FOLDER
ls -lah $INPUT_FOLDER/.git
exit 1

echo ">>>> Getting Pull Request info if exists..."
if [[ -f "$INPUT_FOLDER/pull-request-info" ]]; then
  echo ">>>> Running SonarCloud tests for Pull Request..."
  export PR_ID=$(jq -r '.id' "$INPUT_FOLDER/pull-request-info")
  export PR_BRANCH=$(jq -r '.feature_branch' "$INPUT_FOLDER/pull-request-info")
  export PR_BASE=$(jq -r '.upstream_branch' "$INPUT_FOLDER/pull-request-info")
  docker run -ti -v $(pwd)/$INPUT_FOLDER:/usr/src newtmitch/sonar-scanner:alpine \
    -Dsonar.projectBaseDir=/usr/src \
    -Dsonar.projectKey=$SONAR_PROJECT_KEY \
    -Dsonar.projectName=$SONAR_PROJECT_NAME \
    -Dsonar.organization=$SONAR_PROJECT_ORGANIZATION \
    -Dsonar.pullrequest.provider=bitbucketcloud \
    -Dsonar.pullrequest.bitbucketcloud.owner=$REPOSITORY_OWNER \
    -Dsonar.pullrequest.bitbucketcloud.repository=$REPOSITORY_NAME \
    -Dsonar.pullrequest.key=$PR_ID \
    -Dsonar.pullrequest.branch=$PR_BRANCH \
    -Dsonar.pullrequest.base=$PR_BASE \
    -Dsonar.sources=$REPOSITORY_SOURCES \
    -Dsonar.host.url=https://sonarcloud.io \
    -Dsonar.login=$SONAR_TOKEN \
    -Dsonar.exclusions=$REPOSITORY_EXCLUSIONS
else
  echo ">>>> Running SonarCloud tests..."
  docker run -ti -v $(pwd)/$INPUT_FOLDER:/usr/src newtmitch/sonar-scanner:alpine \
    -Dsonar.projectBaseDir=/usr/src \
    -Dsonar.projectKey=$SONAR_PROJECT_KEY \
    -Dsonar.projectName=$SONAR_PROJECT_NAME \
    -Dsonar.organization=$SONAR_PROJECT_ORGANIZATION \
    -Dsonar.sources=$REPOSITORY_SOURCES \
    -Dsonar.host.url=https://sonarcloud.io \
    -Dsonar.login=$SONAR_TOKEN \
    -Dsonar.exclusions=$REPOSITORY_EXCLUSIONS
fi


