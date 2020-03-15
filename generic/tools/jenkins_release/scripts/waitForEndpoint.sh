URL="$1"
WAIT_TIME=$2
WAIT_COUNT=$3

count=0

sleep 20

until [[ $(curl -Isf --insecure "${URL}") ]] || [[ $count -eq ${WAIT_COUNT} ]]
do
    echo ">>> waiting for ${URL} to be available"
    sleep ${WAIT_TIME}
    count=$((count + 1))
done

if [[ $count -eq ${WAIT_COUNT} ]]; then
  echo ">>> Retry count exceeded. ${URL} not available"
  exit 1
else
  echo ">>> ${URL} is available"
fi

