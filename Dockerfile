# -----------------------------------------------------------------------------
# docker-agskies2
#
# A dockerized minecraft server for the Agrarian Skies 2
#
# Needs work, comments and serious polish
#
# Authors: Brian Eilber
# Updated: March 27th, 2016
# Require: Docker (http://www.docker.io/)
# -----------------------------------------------------------------------------


FROM    ubuntu:14.04

MAINTAINER Brian Eilber <brian.eilber@gmail.com>

ENV     DEBIAN_FRONTEND noninteractive

RUN     apt-get --yes update && \
	apt-get --yes upgrade && \
	apt-get --yes install software-properties-common

RUN     sudo apt-add-repository --yes ppa:webupd8team/java && apt-get --yes update
RUN     echo debconf shared/accepted-oracle-license-v1-1 select true | debconf-set-selections  && \
        echo debconf shared/accepted-oracle-license-v1-1 seen true | debconf-set-selections  && \
        apt-get --yes install curl oracle-java8-installer unzip && \
        apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN     mkdir /server
RUN     wget http://ftb.cursecdn.com/FTB2/modpacks/FTBInfinity/2_5_0/FTBInfinityServer.zip -O /server/pack.zip
RUN	cd /server && unzip pack.zip && rm pack.zip

RUN	sh /server/FTBInstall.sh



RUN     echo "eula=true" > /server/eula.txt

EXPOSE	25565
EXPOSE	8123

VOLUME	["/data"]

#COPY	start.sh /server/start.sh

#RUN	chmod +x /server/start.sh
RUN	chmod +x /server/ServerStart.sh
#CMD	["/server/start.sh"]
CMD	["/server/ServerStart.sh"]
