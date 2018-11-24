#!/bin/sh

DIR="$(mktemp -d -p .)"
COUNTER=0
MONGODB_URI="$(jq '.mongodb.uri' < configs/mongodb.json | sed -e 's/^"\(.*\)"$/\1/')"

mongo --quiet \
      --eval 'db.units.find({}, {"_id": 0, "_sc_id_hash": 1}).toArray()' \
      "$MONGODB_URI" \
  | jq -cM '[.[] | {"type": "mongodb_unit", "term": ._sc_id_hash}] | _nwise(50000)' \
  | while read -r line;
do
  echo "$line" > "$DIR/chunk-$COUNTER.json";
  COUNTER=$((COUNTER+1))
done

for i in "$DIR"/*;
do
  echo "$i"
  "$(npm bin)"/sugarcube -c pipelines/migrate-archive.json \
              -q "$i" \
              -d
done

rm -rf "$DIR"
