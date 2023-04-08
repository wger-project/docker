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

### Configuration

Instead of editing the compose file or the env file directly, it is recommended
to extend it. That way you can more easily pull changes from this repository.

For example, you might not want to run the application on port 80 because some
other service in your network is already using it. For this, simply create a new
file called `docker-compose.override.yml` with the following content:

    services:
      nginx:
        ports:
          - "8080:80"

Now the port setting will be overwritten from the configured nginx service when
you do a `docker compose up`. The same applies to the env variables, just create
a new file called e.g. `my.env` and add it after the provided `prod.env` for the
web service (again, this is `docker-compose.override.yml`). There you add the
settings that you changed, and only those, which makes it easier to troubleshoot,
etc.:

    web:
      env_file:
        - ./config/prod.env
        - ./config/my.env

For more information and possibilities consult <https://docs.docker.com/compose/extends/>

### 1 - Start

To start all services:

    docker-compose up -d
  
Optionally download current exercises from wger.de, exercise images and
the ingredients (will take some time):

    docker-compose exec web python3 manage.py sync-exercises
    docker-compose exec web python3 manage.py download-exercise-images
    docker-compose exec web python3 manage.py download-exercise-videos
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
your domain to it. For this just edit the "nginx" service in docker-compose.yml and
set the port to some value, e.g. `"8080:80"` then configure your proxy to forward
requests to it, e.g. for nginx (no other ports need to be changed, they are used
only within the application's docker network):

Also notice that the application currently needs to run on its own (sub)domain
and not in a subdirectory, so `location /wger {` will probably only mostly work. 


```nginx
upstream wger {
    server 123.456.789.0:8080;
}

server {
    listen 80;
    listen [::]:443 ssl;
    listen 443 ssl;

    location / {
        proxy_pass http://wger;
        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_redirect off;
    }

    server_name my.domain.example.com;

    ssl_certificate /path/to/https/certificate.crt;
    ssl_certificate_key /path/to/https/certificate.key;
}
```

### Read this if you use HTTPS

If you want to use HTTPS like in the example config you need to add some
additional configurations. Since the HTTPS connections are reversed proxied,
the secure connection terminates there, the application will receive a regular
HTTP request and django's [CSRF protection](https://docs.djangoproject.com/en/4.1/ref/csrf/)
will kick in.

To solve this, update the env file and either

* manually set a list of your domain names and/or server IPs 
  `CSRF_TRUSTED_ORIGINS=https://my.domain.example.com,https://118.999.881.119`
* or set the `X-Forwarded-Proto` header like in the example and set
  `X_FORWARDED_PROTO_HEADER_SET=True`. If you do this consult the
  [documentation](https://docs.djangoproject.com/en/4.1/ref/settings/#secure-proxy-ssl-header)
  as there are some security considerations.

You might want to set `DJANGO_DEBUG` to true while you are debugging this is you
encounter errors.

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

