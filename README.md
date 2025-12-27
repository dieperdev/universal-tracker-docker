# universal-tracker-docker

This repository contains a docker port of the ArchiveTeam [universal-tracker](https://github.com/ArchiveTeam/universal-tracker).

Why? The [other docker port](https://github.com/marked/universal-tracker/tree/docker-redisgem2) on the [official tracker documentation](https://wiki.archiveteam.org/index.php/Dev/Tracker) doesn't work (it throws Ruby errors while parsing page content).

## Table of contents
- [How this differs from the original universal-tracker](#how-this-differs-from-the-original-universal-tracker)
  - [Redis](#redis)
  - [Tracker](#tracker)
  - [Broadcaster](#broadcaster)
  - [Target](#target)
- [Things to note](#things-to-note)
  - [Tracker URL](#tracker-url)
  - [stdin: is not a tty](#stdin-is-not-a-tty)
  - [Backfeed and multi-item claiming](#backfeed-and-multi-item-claiming)
- [Running this project](#running-this-project)
- [Extras](#extras)
- [License](#license)

## How this differs from the original universal-tracker
### Redis
  - The [official tracker documentation](https://wiki.archiveteam.org/index.php/Dev/Tracker) doesn't pin Redis to a specific version and instead pulls from the latest stable release. This repository uses a [Redis alpine image pinned to 8.2.3](https://hub.docker.com/layers/library/redis/8.2.3-alpine), which is *almost* the latest release, at the time of writing.
### Tracker
  - Use `bash` to interact with the tracker terminal, not `sh`
  - `source /usr/local/rvm/scripts/rvm` must be ran in the terminal session before you interact with Ruby (if it hasn't been ran in the session already). This is a minor inconvenience but it's likely due to the way `rvm` is installed.
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

## Things to note
### Tracker URL
When running your custom (or prebuilt) grab container, you should change all mentions of `legacy-api.arpa.li` and `tracker.archiveteam.org` (including but not limited to `pipeline.py` and `*.lua`) to the name of the tracker service in `docker-compose.yml`. Not changing this could mess with the data on the real tracker and get you banned.

<hr />

### stdin: is not a tty
You may get a message like `stdin: is not a tty` when running the tracker. It is normal and the tracker will still run.

<hr />

### Backfeed and multi-item claiming
The open source universal-tracker does not support backfeed and multi-item claiming. To disable multi-item claiming (so you can test a -grab project locally), do the following to your `pipeline.py`. The telegram-grab is used as an example:
Reference: [lines 352-354](https://github.com/ArchiveTeam/telegram-grab/blob/master/pipeline.py#L352-L354) of the `pipeline.py` script from [telegram-grab](https://github.com/ArchiveTeam/telegram-grab)
1. Remove `multi={}/` from the `GetItemFromTracker` function (leave the trailing slash `/`)
2. Remove `, MULTI_ITEM_SIZE` from the `GetItemFromTracker` function (no trailing comma `,` should be left in the `format` function)

Backfeed functions will refuse to work (not implemented in the open source universal-tracker) and 404 errors will be shown in the tracker when backfeed requests are received.

## Running this project
*If you have docker compose v1 (`docker-compose`), use that instead of `docker compose` (docker compose v2). Compose v1 compatibility has not been tested, so [YMMV](https://en.wiktionary.org/wiki/YMMV).*
1. Clone this repository
2. cd into the directory: `cd universal-tracker-docker/`, any commands with `docker compose` must now be ran in this directory
3. Run `docker compose build` — This takes a long time, usually 15 minutes. If it looks like the output froze (especially while running Ruby commands), it hasn't. Be patient. If this runs for a lot longer (and you are on decent hardware), open an issue.
4. Run `docker compose up -d`
5. Follow instructions on the [official universal-tracker repo](https://github.com/ArchiveTeam/universal-tracker?tab=readme-ov-file#quick-start) after #5 (ignore #5).
6. When you are ready to shutdown universal-tracker, run `docker compose down`

## Extras
If you want to configure universal-tracker further (clearing out old claims, log flushing, and reducing Passenger memory usage), follow the instructions after the [claims section](https://wiki.archiveteam.org/index.php/Dev/Tracker#Claims) on the official tracker documentation.

To run your custom grab image, uncomment lines 49-62 in `docker-compose.yml` and replace the information necessary.

## License
The [official universal-tracker](https://github.com/ArchiveTeam/universal-tracker) repository doesn't include a `LICENSE` file. One may be added soon though.
