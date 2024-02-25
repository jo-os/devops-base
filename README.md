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
## IaC

**Terraform** - Систему инициализации

**Концепция terraform**
- написан на Go
- декларативное описание инфраструктуры
- не имеет привязки к сервису
- использует подключаемые провайдеры

**terraform init**
- создает папку .terraform
- определяет используемые модули и провайдеры
- загружает плагины в .terraform

**terraform plan**
- создает план выполнения
- выполняет обновления
- определяет необходимые действия для желаемого состояния

4 основных вида блоков в языке HCL
- Provider - описывает подключение к сервису который будет искользоваться, а также различные настройки (авторизация, регион, зона)
- Resource - основа конфигурации, описывается аргументами, после создания появляются свои атрибуты
- Data - источники данных позволяют извлекать или вычислять данные для использования внутри терраформ скрипта
- Variables - переменные - input, output, local, бывают простого или составного типа
```
Практика - развернуть loadbalancer и 2 сервера - залить на них через скрипт сайт nodejs
```
https://github.com/jo-os/devops-base/tree/main/terraform

**Ansible** - системы управления конфигурацией

Практика - берем прошлый терраформ, но устанавливаем все через Ansible
```
https://gitlab.com/asomirl/skillbox-meet-ansible - терраформ + ансибл
```
Terraform + https://github.com/jo-os/devops-base/tree/main/ansible

## Виртуализация
Программная виртуализация
 - Эмуляция - самая медленная (денди на пк - преобразуем все для ОС) - например эмуляция мобильных устройств
 - Паравиртуализация - ос подготавлявается для виртуальной среды, ядро подвергается незначительной модификации - более эффективна так как работа с железом практически на прямую, без участия ОС
 - Встроенная виртуализация - поддерживает все системы без изменений (двусторонняя вирутализация - например одна ос в другой)
Аппаратная виртуализация - работает благодоря поддержки со стороны железа - гоствые ос управляются гипервизором напрямую. Технологии - Intel VT, AMD-V

Преимущества аппаратной виртуализации
- Упрощение разработки программных платформ виртуализации
- Возможность увеличения быстродействия
- Безопасность
- Независимость архитектуры

Платформы аппаратной виртуализации - IBM LPAR, VMWare, Hyper-V, Xen, KVM

## Docker

**Контейнеризация** это метод виртуализации при котором ядро операционной системы поддерживает несколько изолированных экземпляров пространства пользователя вместо одного.

**Docker** - открытая платформа для разработки, доставки и запуска приложений. Позволяет отделить приложение от инфраструктуры чтобы мы могли быстро доставлять ПО.

**Docker** - это ПО для автоматизации развертывания и управления приложениями в средах с поддержкой контейнеризации.

**Docker Engine** - клиент-серверное приложение со следующими основными компонентами
- Docker daemon - это сервер Docker, который ожидает запросов к API Docker. Демон Docker управляет образами, контейнерами, сетями и томами.
- Docker CLI - Клиент Docker (Docker Client) — это основное средство, которое используют для взаимодействия с Docker. 

Команды docker
```
docker save image-id > name.tar - сохранили контейнер
docker load < name.tar - вернули контейнер - но он без имени и тэга
docker tag image-id name:tag - добавляем имя и тэг
docker port container-id - покажет порт контейнера
docker tag image-id jooos/image-name:latest - именуем под hub
docker push jooos/image-name - пушим в хаб
```
**Dockerfile** - это файл содержащий набор инструкций следуя которым Docker будет собирать образ контейнера. Этот файл содержит описание базового образа, который будет представлять собой исходный слой образа.

Образ Docker состоит из слоев, каждый из которых представляет инструкцию Dockerfile. Слои уложены друг на друга и каждый из них представляет дельту изменений от предыдущего слоя.

**Основные правила создания Dockerfile**
- Create ephemeral containers - создавайте эфимерные контейнары - контейнер может быть создан и уничтожен
- Understans build context - понимание контекста сборки - при docker build текущий рабочий каталог называется контекстом сборки
- Pipe Dockerfile through - конвейер Dockerfile через стандартный ввод - docker может создавать образы передавая Dockerfile по конвейеру через стандартный ввод
- Exclude with .dockerignore - исключать с dockerignore
- Use multi-stage buids - используйте многоступенчатые сборки
- Don't install unnecessary packages - не устанавливайте ненужный пакеты
- Decouple applications - разделяйте приложение
- Minimize the number of layers - минимизируйте количество слоев
- Sort multi-line argument - сортируйте многострочные аргументы
- Leverage build cache - используйте кэш сборки

**Для сохранения преимущества конейнеров**
- Не надо хранить данные внутри контейнеров
- Не надо дробить доставку приложений
- Не надо создавать большие образы
- Не надо использовать однослойные контейнеры
- Не надо создавать образы из запущенных контейнеров
- Не надо использовать только тэг latest
- Не надо выполнять в контейнере более одного процесса
- Не надо хранить учетные данные в образе
- Не надо запускать процессы от имени root
- не надо полагаться на IP адреса

```
docker create --name my-nginx -p 80:80 nginx:alpine - создаем контейнер, но он не будет запущен - docker ps -a
docker cp index.html my-nginx:/usr/share/nginx/html/index.html - копируем index.html
docker commit my-nginx nginx-hi - получаем образ с измененным index.html
docker run --name test-nginx -d -p 80:80 nginx-hi - тестим
```
**Работа с томами**
- docker volume create -name my_volume
- docker volume ls
- docker volume inspect my_volume
- docker volume rm my_volume
- docker volume prune
- docker system prune

Параметры --mount - предпочтительнее, так как можно указать больше
- type - тип монтирования - bind, volume, tmpfs
- source (src) - источник монтирования - для именованных томов это имя тома
- destination (dst, target) - путь к которому файл или папка монтируется в контейнере
- readpnly - монтирует том, который предназначен только для чтения
```
docker run --mount type=volume,source=volume_myname,destination=/path/in/container,readonly my_image
```
https://github.com/darkbenladan/docker-phpfpm-nginx/tree/master

https://hub.docker.com/repository/docker/jooos/phpfpm-nginx/general

**Виды сетей Docker:**
- host
- bridge
- none
- overlay
- macvlan

**Управление сетями bridge**
- docker network create my-net
- docker network rm my-net
- docker create --name my-container --network my-net -p 80:80 my-container
- docker network connect my-net my-container
- docker network disconnect my-net my-container

**Overlay сеть**
- docker network create -d overlay my-overlay
- docker network create --driver overlay --ingress-subnet=10.0.0.0/16 --gateway=10.0.0.2 --opt=com.docker.network.driver.mtu=1200 my-ingress

**Macvlan**
- docker network create -d macvlan --subnet=192.168.33.0/24 --gateway=192.168.33.254 -o parent=eth0 pub_net
- получаем контейнер в отдельной виртуальной подсети и чтобы до него достучаться
- ip link add mac0 link eth0 type macvlan bridge
- ip addr dd 192.168.33.10/24 dev mac0
- ifconfig mac0 up
- далее контейнеры в macvlan pub_net должны пинговаться

Docker Compose - это инструментальное средство входящее в состав Docker, оно предназначено для решения задач связанных с развертыванием проектов.
```
docker compose up
docker compose down
docker compose logs -f [service]
docker compose ps
docker compose exec [service] [command]
docker compose images
```

## Ansible
```
ansible-playbook my.yml --check
ansible-playbook my.yml --syntax-check
ansible-galaxy install geerlingguy.nginx -p . - скачиваем в текущую папку (-p .)
ansible-inventory --graph
ansible-inventory --graph --vars
```
**Тестирование**
```
Проверка статуса service
Проверка состояния скриптом
Проверка наличия файла
```
Провекра порта:
```yml
tasks:
  wait_for:
    host: {{ ip }}
    port: 22
    delegate_to: localohost
```
Провекра url:
```yml
tasks:
  - action: uri url=http://example.com return_content=yes
    register: webpage
  - fail:
    msg: "not found"
    when: "'Works' not in webpage.content"
```
assert - проверка по условиям - если проверка не пройдет то остановка выполнения
```
tasks:
  - shell: /usr/bin/command --paranetr vakue
    register: result
  - assert:
    that:
    - "'not_ready' not in result.stderr"
    - "'enabled' in result.stdout"
```
**Виды тестирования**
- E2E - end to end - тестирование основного бизнес функционала (напримре http запросы, регистрация пользователя)
- Системное тестирование - тестирование программы в целом (например ручное тестирование)
- - на базе требований - для каждого требования пишут тестовые случаи - тест-кейсы 
  - на базе сценариев использования - use-case based - на основе данных о по создаются сценарии о его использовании
- Интеграционное тестирование - тестирование взаимодействия систем или сервисов, целью которого является проверка того что было спроектировано при создании интеграции между несколькими ПО и того что получлось на выходе по функциональными и техническим требованиям. Есть список правил с оределенными выходными данными - проверяем их.
- Unit тестирование - процесс в программировании позволяющий проверить на корректность отдельные модули исходного кода программы покрывая их тестами. Это тестирование методов какого то классы программы в изоляции от остальной программы - то есть конкретного блока или модуля ПО.
- Mock тестирование - mock это фиктивная реализация интерфейса, предназначенная для тестирования - это тестирование на заглушках, осуществляется внутри системы без похода в другую систему.
