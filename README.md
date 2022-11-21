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

It is recommended to regularly pull the latest version of the images from this
repository, since sometimes new configurations or environmental variables are
added.

### 1 - Start

To start all services:

    docker-compose up -d
  
Optionally download current exercises from wger.de, exercise images and
the ingredients (will take some time):

    docker-compose exec web python3 manage.py sync-exercises
    docker-compose exec web python3 manage.py download-exercise-images
    docker-compose exec web python3 manage.py download-ingredient-images
    docker-compose exec web wger load-online-fixtures

(these steps can be configured to run automatically on startup, see the options
in `prod.env`.)
    

Then open <http://localhost> (or your server's IP) and log in as: **admin**,
password **adminadmin**


### 2 - Update the application

Just remove the containers and pull the newest version:

    docker-compose down
    docker-compose pull
    docker-compose up

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


## Deployment

The easiest way to deploy this application is to use a reverse proxy like nginx
or traefik. You can change the port this application exposes and reverse proxy
your domain to it. For this edit the "nginx" service in docker-compose.yml and
set the port to some value, e.g. `"8080:80"` then configure your proxy to forward
requests to it, e.g. for nginx:

```nginx
server {
    listen 80;
    listen [::]:80;

    location / {
        proxy_pass http://localhost:8080;
    }

    # Increase max body size to allow for video uploads
    client_max_body_size 100M;
}
```

Any other settings such as HTTPS can be configured here as well. Also notice
that the application currently needs to run on its own (sub)domain and not in a
subdirectory, so `location /wger {` will not work. 


## Building

If you want to build the images yourself, clone the wger repository and follow
the instructions for the devel image in the `extras/docker` folder.


## Contact

Feel free to contact us if you found this useful or if there was something that
didn't behave as you expected. We can't fix what we don't know about, so please
report liberally. If you're not sure if something is a bug or not, feel free to
file a bug anyway.

* discord: <https://discord.gg/rPWFv6W>
* issue tracker: <https://github.com/wger-project/docker/issues>
* twitter: <https://twitter.com/wger_project>


## Sources

All the code and the content is freely available:

* <https://github.com/wger-project/>

## Licence

The application is licenced under the Affero GNU General Public License 3 or
later (AGPL 3+).

