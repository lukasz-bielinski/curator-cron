curator --host $ELASTICSEARCH_HOST --port 9200 delete indices --older-than 7  --time-unit days --timestring '%Y-%m-%d'  2>&1
