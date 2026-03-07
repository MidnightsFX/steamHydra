tag=0.8.35

# echo 'Updating packaged ModDB'
# rspec -t update_moddb
rake build
docker build . -t midnightsfx/steamhydra-valheim:${tag}

docker push midnightsfx/steamhydra-valheim:${tag}