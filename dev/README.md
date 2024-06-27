# Development compose file for wger - WIP

https://www.jetbrains.com/help/pycharm/using-docker-compose-as-a-remote-interpreter.html
https://code.visualstudio.com/docs/containers/quickstart-python

## First start

Clone https://github.com/wger-project/wger to a folder of your choice.

Edit `dev/docker-compose.yml` and set the correct `source: /Users/roland/Entwicklung/wger/server` 

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
python3 manage.py runserver 0.0.0.0:8000
```

The server should restart automatically when you change code, etc.