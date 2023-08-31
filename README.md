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
    image: midnightsfx/steamhydra-valheim:0.7.9
    command: start Valheim --debug
    environment:
      #SessionName: ''
      #ServerMap: ''
      #ServerPass: ''
      Port: 2456
      # EnableMods: 'true'
      Public: 'false'
      # SaveInterval: 300
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

## Mods

### Valheim Mods

In order to enable mods the following env variable should be passed.
```
EnableMods: 'true'
```

With mods enabled the server will automatically check for, and download the latest version of BepInEx by default. If you need to pin to a specific version, you can do that by passing the environment variable modloader, eg: `Modloader: '5.4.1903'`

In order to pull in mods you should specify the mod string in a comma-delimited list in the `Mods` environment variable:
```
Mods: 'ValheimArmory,EpicLoot+0.9.20,LVH-IT-UseEquipmentInWater,Smoothbrain-CreatureLevelAndLootControl+4.5.11'
```
There are a few formats that are supported, as shown above. The mod name itself, the mod name-version, modauthor-modname and modauthor-modname-version. The more specific you are the better chance that the exact mod you want will be found and loaded.

**Dependency mods are automatically included!** You do not need to specify dependency mods, if one of your required mods depends on a mod that is not listed it will be downloaded and installed at the dependency required version.

Note: Leaving the version out will mean that the server will regularly check for and install the latest version of the mod.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/midnightsfx/steamhydra.


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).