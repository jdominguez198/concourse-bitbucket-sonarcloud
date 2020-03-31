#!/usr/bin/env bash

: "${INPUT_FOLDER:?}"
: "${REPOSITORY_SSH_KEY:?}"
: "${REPOSITORY_EXCLUSIONS:?}"
: "${REPOSITORY_SOURCES:?}"
: "${SONAR_PROJECT_KEY:?}"
: "${SONAR_PROJECT_NAME:?}"
: "${SONAR_PROJECT_ORGANIZATION:?}"
: "${SONAR_TOKEN:?}"

call_sonarcloud_docker_run () {
  SONAR_COMMAND=(
    "docker run -ti -v $(pwd)/$INPUT_FOLDER:/usr/src newtmitch/sonar-scanner:alpine"
    "-Dsonar.projectBaseDir=/usr/src"
    "-Dsonar.projectKey=$SONAR_PROJECT_KEY"
    "-Dsonar.projectName=$SONAR_PROJECT_NAME"
    "-Dsonar.organization=$SONAR_PROJECT_ORGANIZATION"
    "-Dsonar.sources=$REPOSITORY_SOURCES"
    "-Dsonar.host.url=https://sonarcloud.io"
    "-Dsonar.login=$SONAR_TOKEN"
    "-Dsonar.exclusions=$REPOSITORY_EXCLUSIONS"
  )
  if [[ ! -z "$PR_ID" && ! -z "$PR_BASE" && ! -z "$PR_BRANCH" ]]; then
    SONAR_COMMAND+=(
      "-Dsonar.pullrequest.provider=bitbucketcloud"
      "-Dsonar.pullrequest.bitbucketcloud.owner=$REPOSITORY_OWNER"
      "-Dsonar.pullrequest.bitbucketcloud.repository=$REPOSITORY_NAME"
      "-Dsonar.pullrequest.key=$PR_ID"
      "-Dsonar.pullrequest.branch=$PR_BRANCH"
      "-Dsonar.pullrequest.base=$PR_BASE"
    )
  fi
  $(${SONAR_COMMAND[@]})
}

echo ">>>> Loading repository credentials..."
mkdir -p /root/.ssh && \
    chmod 0700 /root/.ssh && \
    ssh-keyscan bitbucket.org > /root/.ssh/known_hosts && \
    echo "$REPOSITORY_SSH_KEY" > /root/.ssh/id_rsa && \
    chmod 600 /root/.ssh/id_rsa

echo ">>>> Getting Pull Request info if exists..."
if [[ -f "$INPUT_FOLDER/pull-request-info" ]]; then
  echo ">>>> Fetching data from Pull Request"
  export PR_ID=$(jq -r '.id' "$INPUT_FOLDER/pull-request-info")
  export PR_BRANCH=$(jq -r '.feature_branch' "$INPUT_FOLDER/pull-request-info")
  export PR_BASE=$(jq -r '.upstream_branch' "$INPUT_FOLDER/pull-request-info")
  echo ">>>> Fetching files from \"$PR_BASE\" branch..."
  SOURCE_DIR=$(pwd)
  cd $INPUT_FOLDER
#  REPOSITORY_GIT_URL=$(git config --get remote.origin.url)
#  git remote remove origin && git remote add origin $REPOSITORY_GIT_URL && git fetch origin $PR_BASE
  git fetch origin '+refs/heads/'"$PR_BASE"':refs/remotes/origin/'"$PR_BASE"''
  cat .git/config
  cd $SOURCE_DIR
fi

echo ">>>> Running SonarCloud tests..."
call_sonarcloud_docker_run

