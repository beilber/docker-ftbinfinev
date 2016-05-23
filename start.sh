#!/bin/bash
cp -R /server/* /data

cd /data

java -Xms${MEM} -Xmx${MEM} -XX:MaxPermSize=256m -Dfml.queryResult=confirm -jar FTBServer-1.7.10-1614.jar nogui
