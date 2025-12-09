# universal-tracker-docker

This repository contains a docker port of the ArchiveTeam [universal-tracker](https://github.com/ArchiveTeam/universal-tracker).

Why? — The [other docker port](https://github.com/marked/universal-tracker/tree/docker-redisgem2) on the [official tracker documentation](https://wiki.archiveteam.org/index.php/Dev/Tracker) doesn't work (it throws Ruby errors while parsing page content).

## Running this project
*If you have docker compose v1 (`docker-compose`), use that instead of `docker compose` (docker compose v2). Compose v1 compatibility has not been tested, so [YMMV](https://en.wiktionary.org/wiki/YMMV).*
1. Clone this repository
2. cd into the directory: `cd universal-tracker-docker/`, any commands with `docker compose` must now be ran in this directory
3. Run `docker compose build` — This takes a long time, usually 15 minutes. If it looks like the output froze (especially while running Ruby commands), it hasn't. Be patient. If this runs for a lot longer (and you are on decent hardware), open an issue.
4. Run `docker compose up -d`
5. Follow instructions on the [official universal-tracker repo](https://github.com/ArchiveTeam/universal-tracker?tab=readme-ov-file#quick-start) after #5 (ignore #5).
6. When you are ready to shutdown universal-tracker, run `docker compose down`

## Extras
If you want to configure universal-tracker further, follow the instructions after the [claims section](https://wiki.archiveteam.org/index.php/Dev/Tracker#Claims) on the official tracker documentation.
