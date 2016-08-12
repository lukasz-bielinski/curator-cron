echo "elasticsearch host $ELASTICSEARCH_HOST"
echo "indices older that $TTL will be deleted"
curator --host $ELASTICSEARCH_HOST --port 9200 delete indices --older-than $TTL  --time-unit days --timestring '%Y-%m-%d'  2>&1
