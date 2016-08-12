echo "Elasticsearch host: $ELASTICSEARCH_HOST"
echo ""
echo "Indices older than $TTL days will be deleted"
echo ""
curator --host $ELASTICSEARCH_HOST --port 9200 delete indices --older-than $TTL  --time-unit days --timestring '%Y-%m-%d'  2>&1
