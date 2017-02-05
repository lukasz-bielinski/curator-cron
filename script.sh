echo ""
echo "Elasticsearch host: $ELASTICSEARCH_HOST"
echo ""
echo "Indices older than $TTL days will be deleted"
echo ""
echo "Indices older than $TTLW weeks will be deleted"
echo ""
#need to set curator to delete indexes  older than 1 week
 curator --logformat logstash --host $ELASTICSEARCH_HOST --port 9200 delete indices --older-than $TTL  --time-unit days --timestring '%Y-%m-%d' --exclude '^.*marvel.*$'  | jq .
 # curator --logformat logstash --host $ELASTICSEARCH_HOST --port 9200 delete indices --older-than $TTL  --time-unit days --timestring '%Y.%m.%d'   | jq .
sleep 30

 # curator --logformat logstash --host $ELASTICSEARCH_HOST --port 9200 delete indices --older-than $TTLW --time-unit weeks --timestring '%Y-%m-%W'   | jq .
 curator --logformat logstash --host $ELASTICSEARCH_HOST --port 9200 delete indices --older-than $TTLW --time-unit weeks --timestring '%Y.%W' --exclude '^.*marvel.*$'  | jq .

sleep 30

# ###moving indexes to warm nodes
# ##daily indices
# curator --logformat logstash --host $ELASTICSEARCH_HOST --port 9200 allocation --rule box_type=warm indices --time-unit days --older-than 7 --timestring '%Y-%m-%d' | jq .
# ##weekly indices
# curator --logformat logstash --host $ELASTICSEARCH_HOST --port 9200 allocation --rule box_type=warm indices --time-unit weeks --older-than 1 --timestring  '%Y.%W' | jq .
# ##optimize warm indices
# ##daily
# curator --logformat logstash --host $ELASTICSEARCH_HOST --port 9200 optimize indices --older-than 14  --time-unit days  --timestring '%Y-%m-%d' | jq .
# ##weekly
# curator --logformat logstash --host $ELASTICSEARCH_HOST --port 9200 optimize indices --older-than 3  --time-unit weeks  --timestring '%Y.%W' | jq .
#index template
##    "index.routing.allocation.require.box_type": "hot"



##rerouting UNASSIGNED shards
IFS=$'\n'
declare -a dataPodList=($(curl -XGET http://$ELASTICSEARCH_HOST:9200/_cat/nodes |grep ' d ' | awk '{b=$8" "$9" "$10" "$11;   print b}'))
for NODE in "${dataPodList[@]}"
  do
       echo ""
       echo "rerouting shards on node $NODE"
       echo ""
       echo ${#dataPodList[@]}
       NODE1=$(echo $NODE | xargs)
       NODE=$NODE1
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
                       "allow_primary": false
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
        "indices.store.throttle.max_bytes_per_sec" : "50mb",
        "indices.memory.index_buffer_size": "50%",
        "cluster.routing.allocation.disk.watermark.low": "25gb",
        "cluster.routing.allocation.disk.watermark.high": "10gb",
        "cluster.info.update.interval": "2m",
        "threadpool.bulk.queue_size": "1000"
    }
}' | jq .

#replica 2 shard5
#index.merge.scheduler.max_thread_count" : 1 for spinning disks
curl -XPUT $ELASTICSEARCH_HOST:9200/_template/index_template -d '
{
  "template" : "*",
  "settings" : {
    "number_of_replicas" : 2 ,
    "number_of_shards": 5,
    "index.merge.scheduler.max_thread_count" : 1,
    "index.translog.durability": "async",
    "index.translog.sync_interval": "15s",
    "index.translog.flush_threshold_ops": "50000",
    "index.refresh_interval": "10s"
  }
} ' | jq .

##templates for monitoring/es 5
curl -XPUT $ELASTICSEARCH_HOST:9200/_template/custom_monitoring-es-2 -d '
{
    "template": ".monitoring-es-2-*",
    "order": 1,
    "settings": {
        "number_of_shards": 5,
        "number_of_replicas": 2
    }
}'

curl -XPUT $ELASTICSEARCH_HOST:9200/_template/custom_monitoring-kibana-2 -d '
{
    "template": ".monitoring-kibana-2-*",
    "order": 1,
    "settings": {
        "number_of_shards": 5,
        "number_of_replicas": 2
    }
}'

curl -XPUT $ELASTICSEARCH_HOST:9200/_template/custom_monitoring-data-2 -d '
{
    "template": ".monitoring-data-2",
    "order": 1,
    "settings": {
        "number_of_shards": 5,
        "number_of_replicas": 2
    }
}'
