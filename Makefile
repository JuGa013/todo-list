SUBCOMMAND = $(filter-out $@,$(MAKECMDGOALS))

CONTAINER_NAME = todo-list
USER_ID:=$(shell id -u)
GROUP_ID:=$(shell id -g)
export UID = $(USER_ID)
export GID = $(GROUP_ID)
DOCKER_COMPOSE = docker-compose
USER_DOCKER = $(USER_ID):$(GROUP_ID)
DOCKER_PHP = docker exec -u $(USER_DOCKER) -it $(CONTAINER_NAME)_php-fpm sh -c
DOCKER_MYSQL = docker exec -u $(USER_DOCKER) -it $(CONTAINER_NAME)_mysql sh -c
DOCKER_NPM = docker exec -u $(USER_DOCKER) -it $(CONTAINER_NAME)_nodejs sh -c
SYMFONY = $(DOCKER_PHP) "php bin/console ${ARGS}"

##
## ALIAS
## -------
ex: xdebug-enable
dx: xdebug-disable
cc: cache-clear
cup: composer-up
stan: code-analyze
analyse: stan metrics
unit: unit-test
behat: func-test

##
## Project
## -------
.DEFAULT_GOAL := help

help: ## Default goal (display the help message)
help:
	@grep -E '(^[a-zA-Z_-]+:.*?##.*$$)|(^##)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[32m%-20s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'

.PHONY: help

##
## Docker
## -------
start: ## Start environnement docker.
start: docker-compose.yml
	UID=$(USER_ID) GID=$(GROUP_ID) $(DOCKER_COMPOSE) up -d --build
	make dx

init: ## Initialize project
init:
	make start
	make vendor
	cp public/.htaccess.dist public/.htaccess
	make create-db
	make migrate

destroy: ## Destroy all containers & network
destroy:
	$(DOCKER_COMPOSE) down

stop: ## Stop all containers
stop:
	$(DOCKER_COMPOSE) stop

docker-ps: ## List container docker
docker-ps:
	$(DOCKER_COMPOSE) ps

exec-php: ## Exec command inside container php. Use argument ARGS
exec-php:
	$(DOCKER_PHP) "${ARGS}"

exec-mysql: ## Exec command inside container mysql. Use argument ARGS
exec-mysql:
	$(DOCKER_MYSQL) "${ARGS}"

connect: ## Connect sh to given container
connect:
	docker exec -u $(USER_DOCKER) -it $(CONTAINER_NAME)_"${ARGS}" sh

connect-php: ## Connect sh to container php
connect-php:
	docker exec -u $(USER_DOCKER) -it $(CONTAINER_NAME)_php-fpm sh

connect-php-root: ## Connect sh to container as user root
connect-php-root:
	docker exec -it $(CONTAINER_NAME)_php-fpm sh

##
## Manage dependencies
## -------
vendor: ## Install composer dependencies
vendor: composer.lock
	$(DOCKER_PHP) "composer install"

composer-req: ## Add dependency or dev dependency. Use argument ARGS (Example : make require-vendor ARGS="security form" or make require-vendor ARGS="profiler --dev"
composer-req:
	$(DOCKER_PHP) "composer require ${ARGS}"

composer-up: ## Update dependencies
composer-up:
	$(DOCKER_PHP) "composer update ${ARGS}"

sf: ## (Generic) Symfony console | example : make sf "c:c"
	${DOCKER_PHP} "php bin/console ${SUBCOMMAND}"

cache-clear: ## Clear the cache (by default, the dev env is used, use ARGS argument to change)
cache-clear:
	$(DOCKER_PHP) "php bin/console cache:clear --env=$(or $(ENV), dev)"

cache-warmup: ## Clear the cache warmup (by default, the dev env is used, use ARGS arguement to change)
cache-warmup:
	$(DOCKER_PHP) "php bin/console cache:warmup --env=$(or $(ARGS), dev)"

##
## Tools
## -------
xdebug-enable: ## Enable Xdebug
xdebug-enable:
	docker exec -it $(CONTAINER_NAME)_php-fpm sh -c "sed -i 's#;*zend_extension=xdebug.so#zend_extension=xdebug.so#g' /usr/local/etc/php/conf.d/xdebug.ini"
	docker exec -it $(CONTAINER_NAME)_php-fpm bash -c 'kill -USR2 $$(pidof -s php-fpm)'
	make restart-php-fpm

xdebug-disable: ## Disable Xdebug
xdebug-disable:
	docker exec -it $(CONTAINER_NAME)_php-fpm sh -c "sed -i 's#zend_extension=xdebug.so#;zend_extension=xdebug.so#g' /usr/local/etc/php/conf.d/xdebug.ini"
	docker exec -it $(CONTAINER_NAME)_php-fpm bash -c 'kill -USR2 $$(pidof -s php-fpm)'
	make restart-php-fpm

restart-php-fpm:
	docker restart $(CONTAINER_NAME)_php-fpm

##
## TESTS
## ------
unit-test: ## Run phpunit
unit-test: tests
	$(DOCKER_PHP) vendor/bin/simple-phpunit

func-test: ## Run behat
func-test:
	$(DOCKER_PHP) "vendor/bin/behat --stop-on-failure"

func-test-tags: ## Run behat on tags
func-test-tags:
	$(DOCKER_PHP) "vendor/bin/behat --tags=$(TAGS) --stop-on-failure"

code-analyze: ## Run phpstan
code-analyze:
	$(DOCKER_PHP) "vendor/bin/phpstan analyze src"

phpstan-generate-baseline: ## To be run if "Ignored error pattern ..." appear with phpstan to update now fix errrors
phpstan-generate-baseline:
	$(DOCKER_PHP) "vendor/phpstan/phpstan/phpstan analyze src --generate-baseline"

metrics: ## Run phpmetrics and moves the directory to be accessible via localhost/phpmetrics/index.html
	$(DOCKER_PHP) "./vendor/bin/phpmetrics --config=.phpmetrics.json"
	$(DOCKER_PHP) "php ./phpmetrics_utils.php analyse"

metrics-generate: ## Saves the latest results into baseline file for analysis
	$(DOCKER_PHP) "php ./phpmetrics_utils.php generate"

##
## Database
## -------
migration: ## Create a migration file
migration:
	make sf "make:migr"

migrate: ## Execute all migration
migrate:
	${DOCKER_PHP} "php bin/console d:m:m -n --allow-no-migration"

diff-migration: ## Execute diff
diff-migration:
	${DOCKER_PHP} "php bin/console doctrine:migration:diff"

db-up: ## Execute up migration
db-up:
	make sf "doctrine:migration:execute -n --up $(VERSION)"

db-down: ## Execute down migration
db-down:
	make sf "doctrine:migration:execute -n --down $(VERSION)"

dump-sql: ## Dump sql schema
dump-sql:
	make sf "d:s:u --dump-sql"

create-db: ## Creates the database
	${DOCKER_PHP} "php bin/console d:d:c"

drop-db: ## Creates the database
	${DOCKER_PHP} "php bin/console d:d:d --force"

rebuild-db: ## Recreate DB and plays migrations
rebuild-db:
	make drop-db
	make create-db
	make migrate
