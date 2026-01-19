SHELL := /bin/bash
COMPOSE_FILE := srcs/docker-compose.yml

all: build up

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
	rm -rf srcs/requirements/nginx/ssl || true

.PHONY: all build up start stop restart down clean
