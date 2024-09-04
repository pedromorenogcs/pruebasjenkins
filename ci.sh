#!/bin/bash
git add .
git commit -m "commit"
git push
curl -X POST "http://pmoreno:11a689a52b07400d59883f3be91790a01c@192.168.33.10:8080/job/pipelineAnsible/build"
