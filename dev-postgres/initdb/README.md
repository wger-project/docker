# Postgres init scripts

This folder contains some SQL scripts that are applied by postgres **once**, on
the very first start against an empty data volume.

They run some initialisation tasks, such as trimming the db and resetting passwords.
Note that the files are run by postgres in alphabetical order. If you want to skip
a file, just rename it to have a non-recognised extension (e.g. `.txt`).
