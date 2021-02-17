FROM ruby:2.7.2-buster

RUN apt-get update \
    && apt-get -y install curl libc6-i386 lib32gcc1

WORKDIR /steamcmd
RUN curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -

# This setup is designed for local builds and testing
# If you are building this yourself you will need to install dependencies and build the gem locally
COPY pkg/steamhydra-0.1.1.gem /gem/steamhydra-0.1.1.gem
# Since this is a local install the dependencies need to be already installed
RUN gem install thor
RUN gem install --local /gem/steamhydra-0.1.1.gem

# Use a persistent volume for game data, setup, saves and backups
VOLUME /server/

WORKDIR /server
ENTRYPOINT ["steamhydra"]