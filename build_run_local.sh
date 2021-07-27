echo 'Ensure changes are tracked in git'
rm ./pkg/*
rake build
docker-compose up --build --force-recreate