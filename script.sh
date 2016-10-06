echo ""
echo "Elasticsearch host: $ELASTICSEARCH_HOST"
echo ""
echo "Indices older than $TTL days will be deleted"
echo ""
curator --logformat logstash --host $ELASTICSEARCH_HOST --port 9200 delete indices --older-than $TTL  --time-unit days --timestring '%Y-%m-%d'   | jq .
curator --logformat logstash --host $ELASTICSEARCH_HOST --port 9200 delete indices --older-than $TTL  --time-unit days --timestring '%Y.%m.%d'   | jq .




##rerouting UNASSIGNED shards
dataPodList=$(curl -XGET http://$ELASTICSEARCH_HOST:9200/_cat/nodes |grep ' d ' | awk '{ $1=$2=$3=$4=$5=$6=$7=""      ;print $0}')
for NODE in $dataPodList
  do
       echo ""
       echo "rerouting shards on node $NODE"
       echo ""
       IFS=$'\n'
       for line in $(curl -s $ELASTICSEARCH_HOST:9200/_cat/shards | fgrep UNASSIGNED); do
         INDEX=$(echo $line | (awk '{print $1}'))
         SHARD=$(echo $line | (awk '{print $2}'))
         curl -XPOST $ELASTICSEARCH_HOST:9200/_cluster/reroute -d '{
            "commands": [
               {
                   "allocate": {
                       "index": "'$INDEX'",
                       "shard": '$SHARD',
                       "node": "'$NODE'",
                       "allow_primary": true
                 }
               }
           ]
         }' | jq .
       done
  done

###https://www.elastic.co/guide/en/elasticsearch/guide/current/indexing-performance.html#segments-and-merging
  curl -XPUT $ELASTICSEARCH_HOST:9200/_cluster/settings -d '
  {
      "persistent" : {
          "indices.store.throttle.max_bytes_per_sec" : "5mb"
      }
  }' | jq .


#replica 2
curl -XPUT $ELASTICSEARCH_HOST:9200/_template/index_template -d '
{
  "template" : "*",
  "settings" : {"number_of_replicas" : 2 }
} ' | jq .
