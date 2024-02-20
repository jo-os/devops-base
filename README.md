# devops-base
DevOps. Основы

**Основные задачи**
- Администрирование серверов
- Обеспечение их отказоустойчивости
- Мониторинг и реагирование на проблемы
- Автоматизация решения проблем
- Автоматизация выкладки приложений на сервера
- Организация процессов работы с кодом
- Описание серверов, сервисов и сети в виде кода

Перенос репозитория с github на gitlab
```
git clone git@gitlab.com:my.git
git remote add out git@github.com:code.git
git remote -v
git fetch out
git branch develop out/master
git checkout develop
git pull
git push -u origin -o merge_request.create
```
Автоматизация - добавляем скрипт в crontab
```sh
#!/bin/bash

cd ./git-to-git/
git checkout develop
git pull
git push -u origin -o merge_request.create
cd ..
```
**Тестированиа кода Python**
- pytest - модульные тесты
- flake8 и pylint - статический анализ
- mypy - проверка типов переменных

**Gitlab CI** - .gitlab-ci.yml
- pipline
  - stage
    - job
```yml
stages:
    - test
    - build
    
unit test:
    stage: test
    script:
        - echo "unit test"

linter:
    stage: test
    script:
        - echo "linter test"

type test:
    stage: test
    script:
        - echo "type test"

build: 
    stage: build
    script:
        - echo "build all"
```
**Триггерные события**
- Запуске при получении нового кода (по умолчанию)
- Запуск при мердж-реквесте
- Запуск в специально ветке или тэге (only: - master  - /^release_[0-9]+(?:.[0.9]+)+$/)
- Ручной запуск (when: manual)
```yml
stages:
    - test
    - build
    - test2
    - dev
    - stage
    - prod
    
install_env:
    stage: test
    script:
        - echo "install"

run_tests:
    stage: test
    script:
        - echo "test"

build: 
    stage: build
    script:
        - echo "build all"


tests_after_build:
    stage: test2
    script:
        - echo "after test"

deploy_dev:
    stage: dev
    script:
        - echo "deploy dev"
    when: manual

deploy_stage:
    stage: stage
    script:
        - echo "deploy stage"
    when: manual
    only:
        refs:
            - tags
            - master
            - /^release.*$/

deploy_prod:
    stage: prod
    script:
        - echo "deploy prod"
    when: manual
    only:
        refs:
            - tags
            - master
            - /^release.*$/
```
**Stage** - близкий к производственному сервер.

Добавляем шаг доставки
- ставим сервер
- добавляем раннер
- ставим nginx
```yml
deploy_dev:
    stage: stage
    script:
        - cp -r ./html/* /var/www/html # копируем новый стайт
        - rm -f /var/www/html/site.zip; zip -r /var/www/html/site.zip ./html # создаем архив
    when: manual
    tags: # тэг раннера
        - stage-shell
    only:
      refs:
        master
```
CI - ускоряет разработку - чем раньше обнаружена ошибка тем проще и быстрее ее исправить

**Реализация рекомендованная Gitlab CI**
- create new branch
- push code
- automated build and test
- push code fixes
- automated build and test
- review and approve
- merge
- CD

**Варианты проверки кода**
- Bugs
- Code quality
- Perfomance
- Security

```
sudo apt install yarn
sudo apt install nodejs
sudo apt install npm
node -v 
npm install -g n             
n latest

yarn global add create-react-app
~/.yarn/bin/create-react-app test-react-app

cd test-react-app
yarn start
ip:3000
```
```
git init
git remote add origin git@gitlab.com:netjoos/test-react-app.git
git add .
git commit
git push -u origin --all
```
```
docker run -d --name gitlab-runner --restart always \
  -v /srv/gitlab-runner/config:/etc/gitlab-runner \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /var/www:/www \
  gitlab/gitlab-runner:latest

docker run --rm -it -v /srv/gitlab-runner/config:/etc/gitlab-runner gitlab/gitlab-runner register
Enter the GitLab instance URL (for example, https://gitlab.com/):
https://gitlab.com/
....
Enter an executor: custom, ssh, parallels, docker+machine, instance, shell, virtualbox, docker, docker-windows, kubernetes, docker-autoscaler:
docker
```
gitlab-ci.yml
```
image: node:20.11-slim

test:
  script:
    - yarn install
    - CI=true yarn test
```
**Stages** - стадии

**Jobs** - задачи - входят в stages - выполняются параллельно внутри одного stage

Состояние контейнера не сохраняется между stage, чтобы файлы были доступны необходимо создавать пути к артефактам
```yml
image: node:20.11-slim
stages:
  - build
  - test

install_dependencies:
  stage: build
  script: yarn install
  artifacts: # добавляем артифакты по пути
    paths:
      - node_modules
  cache: # добавляем кеш - проверяем его валидность по yarn.lock
    paths:
      - node_modules
    key:
      files:
        - yarn.lock

run_tests: 
  stage: test
  script:
    - CI=true yarn test
```
Добавить проверку линтером для nodejs
```
yarn add eslint --dev
yarn run eslint --init
yarn run eslint src/**.js # проверка
```
```
run_linter:
  stage: test
  script: yarn run eslint src/**.js
```
Требования к деплою
- атомарность
- обратимость

Методы деплоя
- сине-зеленый
- канареечный

Автоматизируем атомарность через симлинк
настройка докера для доступа к /var/www
- nano /srv/gitlab-runner/config/config.toml
- volumes = ["/cache","/var/www/:/www:rw"]
```yml
stages:
  - build
  - test
  - deploy

install_dependencies:
  image: node:20.11-slim
  stage: build
  script:
    - yarn install
    - yarn build
  artifacts:
    paths:
      - node_modules
      - build
  cache:
    paths:
      - node_modules
    key:
      files:
        - yarn.lock


test:
  stage: deploy
  script:
    - cp -r build /www/test-app/$CI_COMMIT_SHA
    - ln -fsnv /var/www/test-app/$CI_COMMIT_SHA /www/html
```
Вариант отката
```yml
test:
  stage: deploy
  script:
    - cp -r build /www/test-app/$CI_COMMIT_SHA
    - cp -Pv /www/html /www/test-app/$CI_COMMIT_SHA/prev-version # копируем содержимое
    - ln -fsnv /var/www/test-app/$CI_COMMIT_SHA /www/html

revert:
  stage: revert
  when: manual
  script:
    - cp -Rv --remove-destination /www/test-app/$CI_COMMIT_SHA/prev-version /www/html 
# --remove-destination - означает что сначало /var/www/html будет удалена и только потом будет скопировано содержимое
```
**Предопределенные переменные**
- CI_COMMIT_SHA	- The commit revision the project is built for.
- CI_COMMIT_REF_NAME - The branch or tag name for which project is built.
- CI_COMMIT_TAG	-	The commit tag name. Available only in pipelines for tags.

Вывод всех переменных в pipeline
```yml
stages:
  - print_vars

print_vars:
  stage: print_vars
  script:
    - export
```
Пользовательские переменные
```
variables:
  docker_html_path: "/www"

$docker_html_path - использование
```

Публикация на разные окружения
- Develop
- Staging
- Prod

nginx
```
server {
        listen 81;
        root /var/www/staging;
        autoindex on;
        index index.html index.htm index.nginx-debian.html;
        server_name _;
        location / {
                try_files $uri $uri/ =404;
        }
}
```
```yml
stages:
  - build
  - test
  - deploy
  - revert

variables:
  docker_html_path: "/www"
  env: prod
  deploy_subfolder: html

install_dependencies:
  image: node:20.11-slim
  stage: build
  script:
    - yarn install
    - yarn build
    - mv build build_$env
  artifacts:
    paths:
      - node_modules
      - build
      - build_$env
  cache:
    paths:
      - node_modules
    key:
      files:
        - yarn.lock

build_staging:
  extends: install_dependencies
  variables:
    env: staging
    REACT_APP_WEBSITE_PREFIX: "[staging] "
    PUBLIC_URL: "/$CI_COMMIT_BRANCH"

test:
  stage: deploy
  script:
    - cp -r build /www/test-app/$CI_COMMIT_SHA
    - cp -Pv /www/html /www/test-app/$CI_COMMIT_SHA/prev-version
    - ln -fsnv /var/www/test-app/$CI_COMMIT_SHA /www/html

deploy_staging:
  extends: deploy_prod
  variables:
    deploy_subfolder: staging/$CI_COMMIT_BRANCH
    env: staging
  when: always
  only:
    - master
    - feature-.*

deploy_prod:
  stage: deploy
  script:
    - cp -r build_$env /www/test-app/${env}_$CI_COMMIT_SHA
    - cp -Pv /www/$deploy_subfolder /www/test-app/${env}_$CI_COMMIT_SHA/prev-version
  only:
    - master

activate_staging:
  extends: activate_prod
  variables:
    deploy_subfolder: staging/$CI_COMMIT_BRANCH
    env: staging
  when: always
  only:
    - master
    - feature-.*

activate_prod:
  stage: deploy
  script:
    - ln -fsnv /var/www/test-app/${env}_$CI_COMMIT_SHA /www/$deploy_subfolder
  when: manual
  only:
    - master

revert:
  stage: revert
  when: manual
  script:
    - cp -Rv --remove-destination /www/test-app/$CI_COMMIT_SHA/prev-version /www/html
```
