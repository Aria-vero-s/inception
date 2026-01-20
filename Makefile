SHELL := /bin/bash
COMPOSE_FILE := srcs/docker-compose.yml
DATA_DIR := /home/asaulnie/data

all: volumes build up

volumes:
	mkdir -p $(DATA_DIR)/mysql
	mkdir -p $(DATA_DIR)/wordpress

build:
	docker compose -f $(COMPOSE_FILE) build --no-cache

up:
	docker compose -f $(COMPOSE_FILE) up -d

start:
	docker compose -f $(COMPOSE_FILE) start

stop:
	docker compose -f $(COMPOSE_FILE) stop

restart: stop start

down:
	docker compose -f $(COMPOSE_FILE) down --volumes --remove-orphans

clean: down

fclean: clean
	rm -rf $(DATA_DIR)
	docker stop $$(docker ps -qa) 2>/dev/null || true
	docker rm $$(docker ps -qa) 2>/dev/null || true
	docker rmi -f $$(docker images -qa) 2>/dev/null || true
	docker volume rm $$(docker volume ls -q) 2>/dev/null || true
	docker network rm $$(docker network ls -q) 2>/dev/null || true
	rm -rf ./

.PHONY: all volumes build up start stop restart down clean fclean