<img src="https://raw.githubusercontent.com/wger-project/wger/master/wger/core/static/images/logos/logo.png" width="100" height="100" />


# Production...ish docker-compose image for wger

🚧 in construction 🚧


## Usage

This docker-compose file starts up a production environment with gunicorn
as the webserver, postgres as a database and redis for caching with nginx
used as a reverse proxy.

The database, static files and uploaded images are mounted as volumes so
the data is persisted. The only thing you need to do is update the images.

### 1 - Start all services

To start all services:

    docker-compose up

Then open <http://localhost> (or your server IP) and log in as: **admin**,
password **admin**


### 2 - Lifecycle Management

To stop all services issue a stop command, this will preserve all containers
and volumes:

    docker-compose stop

To start everything up again:

    docker-compose start

To remove all containers (except for the volumes)

    docker-compose down

To view the logs:

    docker-compose logs -f

### 3 - Other commands

You might need to issue other commands or do other manual work in the container,
e.g.

     docker-compose exec web yarn install
     docker-compose exec --user root web /bin/bash


## Building

If you want to build the images yourself, clone the wger repository and follow
the instructions for the appropriate images in the extras/docker folder.


## Contact

Feel free to contact us if you found this useful or if there was something that
didn't behave as you expected. We can't fix what we don't know about, so please
report liberally. If you're not sure if something is a bug or not, feel free to
file a bug anyway.

* gitter: <https://gitter.im/wger-project/wger>
* issue tracker: <https://github.com/wger-project/docker/issues>
* twitter: <https://twitter.com/wger_project>


## Sources

All the code and the content is freely available:

* <https://github.com/wger-project/>

## Licence

The application is licenced under the Affero GNU General Public License 3 or
later (AGPL 3+).

