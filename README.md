# universal-tracker-docker

This repository contains a docker port of the ArchiveTeam [universal-tracker](https://github.com/ArchiveTeam/universal-tracker).

Why? — The [other docker port](https://github.com/marked/universal-tracker/tree/docker-redisgem2) on the [official tracker documentation](https://wiki.archiveteam.org/index.php/Dev/Tracker) doesn't work (it throws Ruby errors while parsing page content).

## How this differs from the original universal-tracker
### Tracker
  - Use `bash` to interact with the tracker terminal, not `sh`
  - `source /usr/local/rvm/scripts/rvm` must be ran in the terminal session before you interact with Ruby (if it hasn't been ran in the session already). This is a minor inconvenience but it's likely die to the way `rvm` is installed.
  - Ruby 2.2.2 is specifically installed (the version to use is not specified in the official tracker documentation) because other Ruby versions caused problems and 2.2.2 was supported by all packages
  - `rvm use 2.2.2` is ran after `rvm install 2.2.2`, it's not needed but makes sure Ruby 2.2.2 is used.
  - bundler (v. `1.17.3`), rack (v. `2.1.4.4`), and passenger (v. `6.0.22`) are installed because they were compatible with Ruby 2.2.2 (the versions of these packages to use are not specified in the official tracker documentation)
  - All config files that need to be edited are automatically done for you. The code is messy, but it works.
  - An Upstart configuration file is provided, but it is not used to start the container
  - `bundle install` without `--binstubs --force` failed to start, so they were added
  - `apt` packages installed to build the tracker (that are no longer needed) are removed after the tracker is built
### Broadcaster
  - The Node.js version to use isn't specified on the [official tracker documentation](https://wiki.archiveteam.org/index.php/Dev/Tracker), so Node.js version 6 is used because it works without errors
  - The [package.json](https://github.com/marked/universal-tracker/raw/refs/heads/docker-redisgem2/broadcaster/package.json) from the [broken docker port](https://github.com/marked/universal-tracker/raw/refs/heads/docker-redisgem2) is used because it contains working `redis` and `socket.io` package versions.
  - An Upstart configuration file is provided, but it is not used to start the container
### Target
  - This uses a dockerized target version from [Fusl/ateam-airsync](https://github.com/Fusl/ateam-airsync), the official ArchiveTeam documentation for setting up a target from scratch is available [here](https://wiki.archiveteam.org/index.php/Dev/Staging). Make sure to read the documentation on [Fusl/ateam-airsync](https://github.com/Fusl/ateam-airsync) and adjust environment variables accordingly.

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
