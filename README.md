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








