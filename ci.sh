#!/bin/bash
GIT_SSH_COMMAND='ssh -i $HOME/.ssh/pruebasM2MGitHub -o IdentitiesOnly=yes' git pull
git add .
git commit -m "commit"
GIT_SSH_COMMAND='ssh -i $HOME/.ssh/pruebasM2MGitHub -o IdentitiesOnly=yes' git push
#curl -X POST "http://pmoreno:11ba538babc21e3cd99e5295e2b55faf87@192.168.33.10:8080/job/pipelineAnsible/build"
#curl -X POST "http://pmoreno:11e282da32a3b34dedb7615d650da5a70a@192.168.33.10:8080/job/pipelinePrueba/build"
