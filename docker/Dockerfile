FROM perl:latest

RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get install -y build-essential && \
    apt-get install -y cpanminus libtidy-dev libxml++2.6-dev libhtml-tidy-perl && \
    cpanm --notest Test::Exception && \
    cpanm --notest Perlanet@v3.0.0 && \
    cpanm --notest LWP::Protocol::https

