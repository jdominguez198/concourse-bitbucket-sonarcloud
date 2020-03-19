# Concourse BitBucket Sonarcloud

This image is used to work with Concourse and allow the user to analyze a Pull Request with SonarCloud, integrating it
with BitBucket UI. This requires to use [BitBucket PullRequest Resource](https://github.com/jdominguez198/bitbucket-pullrequest-resource)
in the Pipeline as a resource to listen Pull Request creation/updates.

Optimized for use with [Concourse CI](http://concourse.ci/).

The image is Alpine based, and includes Docker, Docker Compose, and Docker Squash, as well as Bash.

Image published to Docker Hub: [jdominguez198/concourse-bitbucket-sonarcloud](https://hub.docker.com/r/jdominguez198/concourse-bitbucket-sonarcloud/).

Inspired by [karlkfi/concourse-dcind](https://github.com/karlkfi/concourse-dcind).

## Build

```
docker build -t jdominguez198/concourse-bitbucket-sonarcloud .
```

## Example

Here is an example of a Concourse [job](http://concourse.ci/concepts.html) that uses ```jdominguez198/concourse-bitbucket-sonarcloud``` image to run the sonarcloud analysis tool.

```yaml
resources:
- name: pullrequest
  type: bitbucket-pullrequest
  icon: bitbucket
  source:
    username: ((bitbucket_username))
    password: ((bitbucket_password))
    project: my-team
    repository: my-repo
    listenBranch: branch
    log_level: INFO
    git:
      uri: git@bitbucket.org:my-team/my-repo.git
      private_key: ((deploy_key))
  check_every: 3m

jobs:
- name: sonar-scanner
  plan:
    - get: pullrequest
      trigger: true
    - put: pullrequest
      params:
        state: INPROGRESS
        name: pullrequest-sonarcloud
        path: pullrequest
    - task: execute-sonarcloud-tool
      privileged: true
      config:
        platform: linux
        image_resource:
          type: docker-image
          source:
            repository: jdominguez198/concourse-bitbucket-sonarcloud
        inputs:
          - name: pullrequest
        run:
          path: entrypoint.sh
        params:
          INPUT_FOLDER: "pullrequest"
          REPOSITORY_EXCLUSIONS: "**/test/**,**/vendor/**,**/component-**/**"
          REPOSITORY_SOURCES: "src/"
          SONAR_PROJECT_KEY: ((sonar_project_key))
          SONAR_PROJECT_NAME: ((sonar_project_name))
          SONAR_PROJECT_ORGANIZATION: ((sonar_project_organization))
          SONAR_TOKEN: ((sonar_token))
```
