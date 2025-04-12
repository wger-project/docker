<img src="https://raw.githubusercontent.com/wger-project/wger/master/wger/core/static/images/logos/logo.png" width="100" height="100" alt="wger logo" />


# docker compose stacks for wger
Contains 3 docker compose environments:

* prod (in root of this repository)
* dev (uses sqlite)
* dev-postgres (uses postgresql)

The production Docker Compose file initializes a production environment with the
application server, a reverse proxy, a database, a caching server, and a Celery
queue, all configured. Data is persisted in volumes, if you want to use folders,
read the warning in the env file.

**TLDR:** just do `docker compose up -d`

For more details, consult the documentation (and the config files):

* production: <https://wger.readthedocs.io/en/latest/production/docker.html>
* development: <https://wger.readthedocs.io/en/latest/development/docker.html>

It is recommended to regularly pull the latest version of the compose file,
since sometimes new configurations or environmental variables are added.

## Contact

Feel free to contact us if you found this useful or if there was something that
didn't behave as you expected. We can't fix what we don't know about, so please
report liberally. If you're not sure if something is a bug or not, feel free to
file a bug anyway.

* Mastodon: <https://fosstodon.org/@wger>
* Discord: <https://discord.gg/rPWFv6W>
* Issue tracker: <https://github.com/wger-project/docker/issues>


## Sources

All the code and the content is freely available:

* <https://github.com/wger-project/>

## Licence

The application is licenced under the Affero GNU General Public License 3 or
later (AGPL 3+).



