#!/bin/bash
git add .
git commit -m "commit"
git push
#curl -X POST "http://pmoreno:11ba538babc21e3cd99e5295e2b55faf87@192.168.33.10:8080/job/pipelineAnsible/build"
curl -X POST "http://pmoreno:11e282da32a3b34dedb7615d650da5a70a@192.168.33.10:8080/job/pipelinePrueba/build"
