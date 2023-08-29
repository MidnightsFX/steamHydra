FROM ruby:3.1.3-buster

RUN apt-get update \
    && apt-get -y install curl libc6-i386 lib32gcc1 libc6-dev

WORKDIR /steamcmd
RUN curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -

# This setup is designed for local builds and testing
# If you are building this yourself you will need to install dependencies and build the gem locally

# the following installs the gem through bundler to get current deps- and then reinstalls the gem through system to expose the executable
# its lazy, but your deps should always be recent, so patching ideally is less of an issue, ensure the built gem has a strict enough version specification if needed.
COPY pkg/steamhydra-0.1.1.gem /gem/steamhydra-0.1.1.gem
RUN gem unpack /gem/steamhydra-0.1.1.gem --target  /gem/
COPY docker-gemfile Gemfile
RUN gem install bundler
RUN bundle install
RUN gem install --local /gem/steamhydra-0.1.1.gem

# Use a persistent volume for game data, setup, saves and backups
VOLUME /server/

WORKDIR /server
ENTRYPOINT ["steamhydra"]