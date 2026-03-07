echo 'Ensure changes are tracked in git'
#echo 'Updating packaged ModDB'
#rspec -t update_moddb
rm ./pkg/*
rake build
docker-compose up --build --force-recreate