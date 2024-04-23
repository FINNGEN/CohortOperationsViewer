#!/bin/bash
source /etc/sandbox/env
export DOCKER_HOST=unix://$XDG_RUNTIME_DIR/docker.sock
notify-send 'Cohort Operations viewer' 'We are starting your application. This could take up to 1min. Browser will be started automatically when ready.'

# update images
docker pull eu.gcr.io/finngen-sandbox-v3-containers/cow:latest


# create config files
echo "
atlasUrl: https://atlas.app.finngen.fi/
" > /tmp/cow_config.yml

docker run --log-driver syslog -d -p 8560:8888 -v /tmp:/tmp  \
    -e COW_CONFIG_FILE="/tmp/cow_config.yml" \
    eu.gcr.io/finngen-sandbox-v3-containers/cow:latest

echo "if the cohort operations viewer does not launch automatically, visit: http://localhost:8560"
#sleep 10
until [ "$(curl -s -o /dev/null -I -w '%{http_code}' "http://localhost:8560")" -eq 200 ]
do
  sleep 5
done
firefox --new-tab 'http://localhost:8560'
