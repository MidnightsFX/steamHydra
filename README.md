# steamhydra

Steam Hydra is designed to provide simple, similar and orchestrated management of steam game servers. Steam game servers are great! Except for all of the dependencies, updates, mod-updates and such that you will need to do in order to keep your server up to date and running!

Included in this repo will be a variety of dockerfiles which are designed to customize the deployment of this gem to manage specific game servers. Currently supported:
* Valheim

## Development and Running Locally

Running a local docker-compose environment can easily be done by:
```
rake build && docker-compose up --build
```
* This builds a new copy of the codebase, note you will need to git commit files which are not already in git history.
* This forces the docker-compose deployment to rebuild the dockerfile, which will pull in the relevant code.


## Usage

For actual deployments, it is suggested to either deploy to a kubernetes cluster or use docker-compose.

Here is an example docker-compose.yaml which could be used.
```
version: "3"
services:
  vahleim:
    image: midnightsfx/steamhydra-valheim:0.1.1
    command: start Valheim --debug
    environment:
      #SessionName: ''
      #ServerMap: ''
      #ServerPass: ''
      Port: 2456
    ports:
      - 2456:2456
      - 2456:2456/udp
      - 2457:2457
      - 2457:2457/udp
      - 2458:2458
      - 2458:2458/udp
    volumes:
      - /mnt/server:/server
```
Note: the actual game server configurations and will be stored on-disk with this configuration `/mnt/server`

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/midnightsfx/steamhydra.


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
