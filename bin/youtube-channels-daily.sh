#!/usr/bin/env bash

SPREADSHEET_IDS="./queries/spreadsheet-ids.txt"

DATE=$(date +%Y-%m-%d)
COUNTER=0
QUERY_COUNT="$(wc -l < "$SPREADSHEET_IDS")"

export NODE_OPTIONS=--max_old_space_size=16384

doit() {
  "$(npm bin)"/sugarcube \
              -c pipelines/youtube_channels_daily.json \
              -q queries/mail-recipients.json \
              -Q sheets_query:YoutubeChannelsDaily \
              --google.spreadsheet_id "$1" \
              -d
}

echo "Starting daily scrape of youtube channels."

while IFS="" read -r ID
do
  if [ $((COUNTER % 10)) -eq 0 ] && [ "$COUNTER" -gt 0 ]
  then
    echo "Processed $COUNTER queries"
  fi

  doit "$ID" 2>&1 | tee -a ./logs/youtube-channels-daily-"$ID"-"$DATE".log

  if [ "$QUERY_COUNT" -eq $((COUNTER + 1)) ]
  then
    exit 0
  fi

  WAIT_TIME=$(((RANDOM % 10)  + 10))
  echo "Sleeping for $WAIT_TIME seconds."
  sleep $WAIT_TIME
  COUNTER=$((COUNTER+1))
done < "$SPREADSHEET_IDS"
