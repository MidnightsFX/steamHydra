FROM ruby:3.2.2-bookworm

# These packages are for Gameserver & tooling support
 RUN apt-get update \
     && apt-get -y install curl libatomic1 libpulse-dev libpulse0

# RUN apt-get update \
#     && apt-get -y install \
#         libc6-dev \
#         libstdc++6 \
#         libsdl2-2.0-0 \
#         libcurl4 \
#         libc6-dev \
#         libsdl2-2.0-0 \
#         curl \
#         iproute2 \
#         libcurl4 \
#         ca-certificates \
#         procps \
#         locales \
#         unzip \
#         libpulse-dev \
#         libatomic1 \
#         libc6

WORKDIR /steamcmd
# These are all for steam CMD
RUN apt-get -y install lib32gcc-s1
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