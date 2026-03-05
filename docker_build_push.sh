tag=0.8.32
rake build
docker build . -t midnightsfx/steamhydra-valheim:${tag}

docker push midnightsfx/steamhydra-valheim:${tag}