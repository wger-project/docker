<img src="https://raw.githubusercontent.com/wger-project/wger/master/wger/core/static/images/logos/logo.png" width="100" height="100" alt="wger logo" />


# Production...ish docker-compose image for wger

## Usage

This docker-compose file starts up a production environment with gunicorn
as the webserver, postgres as a database and redis for caching with nginx
used as a reverse proxy. If you want to develop, take a look at the docker
compose file in the application repository.

The database, static files and uploaded images are mounted as volumes so
the data is persisted. The only thing you need to do is update the docker
images. Consult the docker volume command for details on how to access or
backup this data.

### 1 - Start

To start all services:

    docker-compose up
  
Optionally download exercise images (might take a while):

    docker-compose exec web python3 manage.py download-exercise-images
    

Then open <http://localhost> (or your server's IP) and log in as: **admin**,
password **adminadmin**


### 2 - Update the application

Just remove the containers and pull the newest version:

    docker-compose down
    docker-compose pull
    docker-compose up

If there are database any changes (you will see a warning from django on
the logs), you need to start the migration process yourself as you might
want to make a backup first:

    docker-compose exec web python3 manage.py migrate

### 3 - Lifecycle Management

To stop all services issue a stop command, this will preserve all containers
and volumes:

    docker-compose stop

To start everything up again:

    docker-compose start

To remove all containers (except for the volumes)

    docker-compose down

To view the logs:

    docker-compose logs -f


You might need to issue other commands or do other manual work in the container,
e.g.

     docker-compose exec web yarn install
     docker-compose exec --user root web /bin/bash


## Building

If you want to build the images yourself, clone the wger repository and follow
the instructions for the devel image in the extras/docker folder.


## Contact

Feel free to contact us if you found this useful or if there was something that
didn't behave as you expected. We can't fix what we don't know about, so please
report liberally. If you're not sure if something is a bug or not, feel free to
file a bug anyway.

* discord: <https://discord.gg/rPWFv6W>
* gitter: <https://gitter.im/wger-project/wger>
* issue tracker: <https://github.com/wger-project/docker/issues>
* twitter: <https://twitter.com/wger_project>


## Sources

All the code and the content is freely available:

* <https://github.com/wger-project/>

## Licence

The application is licenced under the Affero GNU General Public License 3 or
later (AGPL 3+).

