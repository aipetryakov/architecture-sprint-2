#!/bin/bash

docker compose exec -T mongo_config_a mongosh --port 27017 --quiet <<EOF
rs.initiate(
  {
    _id : "config",
    configsvr: true,
    version: 1,
    members: [
      { _id: 0, host: "mongo_config_a:27017" }
    ]
  }
);
EOF


docker compose exec -T mongo_shard1_a mongosh --port 27017 --quiet <<EOF
rs.initiate(
    {
      _id : "shard1",
      members: [
        { _id : 0, host : "mongo_shard1_a:27017" }
      ]
    }
);
EOF

docker compose exec -T mongo_shard2_a mongosh --port 27017 --quiet <<EOF
rs.initiate(
    {
      _id : "shard2",
      members: [
        { _id : 0, host : "mongo_shard2_a:27017" }
      ]
    }
);
EOF

docker compose restart mongo_router1
sleep 10s

docker compose exec -T mongo_router1 mongosh --port 27017 --quiet <<EOF
sh.addShard("shard1/mongo_shard1_a:27017");
sh.addShard("shard2/mongo_shard2_a:27017");
sh.enableSharding("somedb");
EOF

docker compose exec -T mongo_router1 mongosh --port 27017 --quiet <<EOF
use somedb
for(var i = 0; i < 1000; i++) db.helloDoc.insertOne({age:i, name:"ly"+i})
EOF

