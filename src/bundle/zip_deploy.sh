#!/bin/bash

uri=`az webapp deployment list-publishing-credentials --ids $1 -o tsv --query scmUri`
curl -X POST --data-binary @$2 $uri/api/zipdeploy?api-version=2020-12-01