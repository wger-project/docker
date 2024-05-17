# Development compose file for wger - WIP

## First start

```shell
UID=${UID} GID=${GID} docker compose up
docker compose exec web /bin/bash
cp extras/docker/development/settings.py .

wger bootstrap
python3 manage.py migrate
```

## Usage
```shell
UID=${UID} GID=${GID} docker compose up
python3 manage runserver 0.0.0.0:8000
```