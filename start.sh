#!/bin/bash
cd /server
java -Xms${MEM} -Xmx${MEM} -XX:MaxPermSize=256m -Dfml.queryResult=confirm -jar FTBServer-1.7.10-1614.jar nogui
