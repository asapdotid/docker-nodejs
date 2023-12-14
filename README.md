# Docker NodeJs (PNPM)

![Docker Automated build](https://img.shields.io/docker/automated/asapdotid/node) ![Docker Pulls](https://img.shields.io/docker/pulls/asapdotid/node.svg)

This project docker image utility CICD on GitLab Runner and running NuxtJs V3 application using PNPM

## Image OS

-   Alpine Linux (3.19)
-   Debian (11.0 - Bullseye slim)

## Additional services

-   Timezone support (default `Asia/Jakarta`)
-   GIT
-   Curl
-   Wget
-   PNPM [Document](https://pnpm.io/motivation)
-   Yarn [Document](https://yarnpkg.com/cli/install)
-   Node Prune [Document](https://gobinaries.com/tj/node-prune)
-   Canvas [Document](https://www.npmjs.com/package/canvas)
-   NuxtJS Production [nuxt-start](https://www.npmjs.com/package/nuxt-start)
-   PM2 [Document](https://pm2.keymetrics.io/docs/usage/docker-pm2-nodejs/)
-   Libcips-tools (Image processing system good for very large ones (tools)) - [Debian](https://packages.debian.org/buster/libvips-tools)
-   Vips (A fast image processing library with low memory needs.) - [Alpine Linux](https://pkgs.alpinelinux.org/package/edge/community/x86/vips)

### Versioning

| Docker Tag | Git Release | Node Version | OS Version    | Support             | Functions                                   |
| ---------- | ----------- | ------------ | ------------- | ------------------- | ------------------------------------------- |
| 18-slim    | Main Branch | 18.19.0      | Bookwarm slim | library Canvas      | Nuxt JS Build Process (GitLab CI/CD)        |
| 18-nuxt    | Main Branch | 18.19.0      | Alpine 3.19   | With images Library | Nuxt JS Running Production (Docker Compose) |
| 20-slim    | Main Branch | 20.10.0      | Bookwarm slim | library Canvas      | Nuxt JS Build Process (GitLab CI/CD)        |
| 20-nuxt    | Main Branch | 20.10.0      | Alpine 3.19   | With images Library | Nuxt JS Running Production (Docker Compose) |

## How To Use

### Package NuxtJS (V3) config

```json
{
  "name": "nuxt-app-v1",
  "description": "Nuxtjs v3 application",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "build": "nuxt build",
    "dev": "nuxt dev",
    "generate": "nuxt generate",
    "preview": "nuxt preview",
    "postinstall": "nuxt prepare",
    "lint": "eslint --ext \".ts,.js,.vue,.html,.json\" --ignore-path .gitignore .",
    "lint:fix": "eslint --fix --ext \".ts,.js,.vue,.html,.json\" --ignore-path .gitignore .",
    "prepare": "husky install && husky set .husky/pre-commit \"pnpm lint-staged\" && husky set .husky/commit-msg  \"npx --no -- commitlint --edit ${1}\"",
    "build:production": "NODE_OPTIONS=--max_old_space_size=1024 nuxt build",
    "start:production": "pm2-runtime start pm2.json --only nuxt-app-v1",
    "reload:production": "pm2-runtime reload pm2.json --only nuxt-app-v1",
    "stop:production": "pm2-runtime stop pm2.json --only nuxt-app-v1",
    "delete:production": "pnpm stop:production && pm2-runtime delete pm2.json --only nuxt-app-v1"
  },
...
}
```

### Run Docker Compose

```yaml
---
version: "3.1"

networks:
    proxy:
        external: true

services:
    nuxt-app:
        container_name: nuxt-app
        image: asapdotid/node:18-nuxt
        restart: unless-stopped
        tty: true
        environment:
            - "TZ=Asia/Jakarta"
        networks:
            - proxy
        expose:
            - "3000"
        volumes:
            - ./project-app:/app:rw
            - ./entrypoint.sh:/entrypoint.sh:ro
        command: sh -c "chmod -R 777 /entrypoint.sh && sh /entrypoint.sh"
```

Sample entrypoint for `NuxtJs version 3`(can edit with your application setup):

```bash
#!/bin/sh

set -o errexit
set -o nounset
set -o pipefail

print_line() {
  echo "-----------------------------------------------------------------------------"
}

setup_applications() {
  echo "Setting up the application"
  if [ -d "./.nuxt" ] && [ -d "./.output" ] && [ -f "./nuxt.config.ts" ] && [ -f "./.env" ] && [ -f "./pm2.json" ]; then
    echo "Project ready for starting, please wait a moment set back and relax!"
    if [ -f "./yarn.lock" ]; then
      /usr/local/bin/yarn start:production
    elif [ -f "./package-lock.json" ]; then
      /usr/local/bin/npm run start:production
    elif [ -f "./pnpm-lock.yaml" ]; then
      /usr/local/bin/pnpm start:production
    fi
  else
    echo "Project ready for starting, please wait a moment to build and start!"
    if [ -f "./yarn.lock" ]; then
      /usr/local/bin/yarn install --frozen-lockfile
      /usr/local/bin/yarn cache clean --force
      /usr/local/bin/yarn build:production
      /usr/local/bin/yarn start:production
    elif [ -f "./package-lock.json" ]; then
      /usr/local/bin/npm ci
      /usr/local/bin/npm cache clean --force
      /usr/local/bin/npm run build:production
      /usr/local/bin/npm run start:production
    elif [ -f "./pnpm-lock.yaml" ]; then
      /usr/local/bin/pnpm install --frozen-lockfile
      /usr/local/bin/pnpm build:production
      /usr/local/bin/pnpm start:production
    fi
  fi
}

main() {
  print_line
  setup_applications
}

main "$@"
```

PM2 Config:

```json
{
    "apps": [
        {
            "name": "nuxt-app-v1",
            "exec_mode": "cluster",
            "instances": "2",
            "script": "./.output/server/index.mjs",
            "watch": true,
            "out_file": "/dev/null",
            "error_file": "/dev/null",
            "env": {
                "HOST": "0.0.0.0",
                "PORT": 3000,
                "NODE_ENV": "production"
            }
        }
    ]
}
```

### GitLab CI (`gitlab-ci.yml`)

Please see `setup & build` job stage, how to use the image.

Sample `gitlab-ci.yml` file for CI/CD **NuxtJS** App (`staging` branch):

```yaml
image: asapdotid/alpine:ssh

stages:
    - init
    - setup
    - build
    - deploy
    - cleaning

variables:
    DOCKER_DRIVER: overlay2
    DEPLOY_SERVER_PATH: "/home/application/nuxt-app-v1"
    DEPLOY_SERVER_ARTIFACTS_PATH: "$DEPLOY_SERVER_PATH/artifacts"
    DEPLOY_SERVER_RELEASES_PATH: "$DEPLOY_SERVER_PATH/releases"
    DEPLOY_SERVER_ACTIVATE_PATH: "$DEPLOY_SERVER_PATH/current"

default:
    before_script:
        - eval $(ssh-agent -s)
        - ssh-add <(echo "${SSH_PRIVATE_KEY}")

# Caches
.node_modules-cache: &node_modules-cache
    key:
        files:
            - pnpm-lock.yaml
    paths:
        - node_modules/
    policy: pull

.pnpm-cache: &pnpm-cache
    key: pnpm-$CI_JOB_IMAGE
    paths:
        - .pnpm-store/
    policy: pull-push

.build-cache: &build-cache
    key: build-$CI_JOB_IMAGE
    paths:
        - .nuxt
        - .output
        - .env
        - public
    policy: pull-push

### INIT STAGING ###
init:staging:
    stage: init
    tags:
        - docker
    rules:
        - if: $CI_COMMIT_BRANCH == "staging"
    script:
        - echo "DEPLOY_USER=root" >> staging.env
        - echo "DEPLOY_SERVER=10.10.0.1" >> staging.env
        - echo "DEPLOY_SERVER_PORT=22" >> staging.env
    artifacts:
        reports:
            dotenv: staging.env

### SETUP STAGING ###
setup:staging:
    stage: setup
    dependencies:
        - init:staging
    rules:
        - if: $CI_COMMIT_BRANCH == "staging"
          # changes:
          #   - "package.json"
          when: always
    tags:
        - docker
    image: asapdotid/node:18-slim
    before_script:
        - pnpm config set store-dir .pnpm-store
    script:
        - pnpm install --frozen-lockfile
    retry:
        max: 2
        when:
            - runner_system_failure
            - stuck_or_timeout_failure
    cache:
        - <<: *node_modules-cache
          policy: pull-push
        - <<: *pnpm-cache
    artifacts:
        expire_in: 1 hour
        paths:
            - node_modules

### BUILD STAGING ###
build:staging:
    stage: build
    dependencies:
        - setup:staging
    rules:
        - if: $CI_COMMIT_BRANCH == "staging"
    tags:
        - docker
    image: asapdotid/node:18-slim
    before_script:
        - pnpm config set store-dir .pnpm-store
        - \cp ./.env.example ./.env
        - PACKAGE_VERSION=$(grep '"version":' ./package.json | cut -d\" -f4);
        - |
            sed -i ./.env \
            -e "s|%%APP_URL%%|$STAGING_APP_URL|g" \
            -e "s|%%API_URL%%|$STAGING_API_URL|g" \
            -e "s|%%GH_PAT%%|$GH_PAT|g" \
            -e "s|%%VERSION%%|$PACKAGE_VERSION-$CI_COMMIT_SHORT_SHA|g";
    script:
        - pnpm build:production
    retry:
        max: 2
        when:
            - runner_system_failure
            - stuck_or_timeout_failure
    artifacts:
        name: "$CI_COMMIT_BRANCH"
        paths:
            - .nuxt
            - .output
            - .env
            - pm2.json
            - nuxt.config.ts
            - package.json
            - pnpm-lock.yaml
            - public
        expire_in: 1 hour
    cache:
        - <<: *node_modules-cache
        - <<: *build-cache

### DEPLOY TO STAGING ###
prepare:release:staging:
    stage: deploy
    needs:
        - job: init:staging
          artifacts: true
        - job: build:staging
          artifacts: true
    rules:
        - if: $CI_COMMIT_BRANCH == "staging"
    tags:
        - docker
    script:
        - |
            tar --exclude='.git' --exclude='.env.example' --exclude='README.md' \
            --exclude='.editorconfig' --exclude='.gitattributes' --exclude='.gitignore' \
            --exclude='.gitlab-ci.yml' --exclude='.gitpod.yml' --exclude='.vscode' --exclude='.husky' --exclude='.pnpm-store' \
            -czf $CI_COMMIT_SHA.tar.gz * .??*
        - ssh -p $DEPLOY_SERVER_PORT $DEPLOY_USER@$DEPLOY_SERVER "mkdir -p $DEPLOY_SERVER_PATH"
        - ssh -p $DEPLOY_SERVER_PORT $DEPLOY_USER@$DEPLOY_SERVER "mkdir -p $DEPLOY_SERVER_ARTIFACTS_PATH"
        - ssh -p $DEPLOY_SERVER_PORT $DEPLOY_USER@$DEPLOY_SERVER "mkdir -p $DEPLOY_SERVER_RELEASES_PATH"
        - ssh -p $DEPLOY_SERVER_PORT $DEPLOY_USER@$DEPLOY_SERVER "chmod -R 755 $DEPLOY_SERVER_PATH"
        - ssh -p $DEPLOY_SERVER_PORT $DEPLOY_USER@$DEPLOY_SERVER "mkdir -p $DEPLOY_SERVER_RELEASES_PATH/$CI_COMMIT_SHA"
        - scp -P $DEPLOY_SERVER_PORT $CI_COMMIT_SHA.tar.gz $DEPLOY_USER@$DEPLOY_SERVER:$DEPLOY_SERVER_ARTIFACTS_PATH
        - |
            ssh -p $DEPLOY_SERVER_PORT $DEPLOY_USER@$DEPLOY_SERVER \
            "tar -xzf $DEPLOY_SERVER_ARTIFACTS_PATH/$CI_COMMIT_SHA.tar.gz -C $DEPLOY_SERVER_RELEASES_PATH/$CI_COMMIT_SHA"
        - |
            ssh -p $DEPLOY_SERVER_PORT $DEPLOY_USER@$DEPLOY_SERVER \
            "find $DEPLOY_SERVER_RELEASES_PATH/$CI_COMMIT_SHA -type d -exec chmod 0755 {} \;"
        - |
            ssh -p $DEPLOY_SERVER_PORT $DEPLOY_USER@$DEPLOY_SERVER \
            "find $DEPLOY_SERVER_RELEASES_PATH/$CI_COMMIT_SHA -type f -exec chmod 0644 {} \;"
    retry:
        max: 2
        when:
            - runner_system_failure
            - stuck_or_timeout_failure
    cache:
        - <<: *node_modules-cache
        - <<: *build-cache

activate:release:staging:
    stage: deploy
    needs:
        - job: init:staging
          artifacts: true
        - job: prepare:release:staging
    rules:
        - if: $CI_COMMIT_BRANCH == "staging"
    tags:
        - docker
    script:
        - ssh -p $DEPLOY_SERVER_PORT $DEPLOY_USER@$DEPLOY_SERVER "mkdir -p $DEPLOY_SERVER_ACTIVATE_PATH"
        - ssh -p $DEPLOY_SERVER_PORT $DEPLOY_USER@$DEPLOY_SERVER "rsync -azrh --delete $DEPLOY_SERVER_RELEASES_PATH/$CI_COMMIT_SHA/ $DEPLOY_SERVER_ACTIVATE_PATH/"
    retry:
        max: 2
        when:
            - runner_system_failure
            - stuck_or_timeout_failure

### CLEANING ARTIFACT & RELEASE STAGING ###
clean:release:staging:
    stage: cleaning
    needs:
        - job: init:staging
          artifacts: true
        - job: activate:release:staging
    rules:
        - if: $CI_COMMIT_BRANCH == "staging"
    tags:
        - docker
    script:
        - ssh -p $DEPLOY_SERVER_PORT $DEPLOY_USER@$DEPLOY_SERVER "cd $DEPLOY_SERVER_ARTIFACTS_PATH && ls -t -1 | tail -n +5 | xargs rm -rf"
        - ssh -p $DEPLOY_SERVER_PORT $DEPLOY_USER@$DEPLOY_SERVER "cd $DEPLOY_SERVER_RELEASES_PATH && ls -t -1 | tail -n +5 | xargs rm -rf"
    retry:
        max: 2
        when:
            - runner_system_failure
            - stuck_or_timeout_failure
```

## License

GNU distributed

## Author Information

[JogjaScript](https://jogjascript.com)

This project was created in 2023 by [Asapdotid](https://github.com/asapdotid). 🚀
