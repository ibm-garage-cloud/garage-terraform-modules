URL="$1"
WAIT_TIME=$2
WAIT_COUNT=$3

count=0

until [[ $(curl -Isf --insecure "${URL}") ]] || \
  [[ $(curl -Iq "${URL}" | grep "403 Forbidden") ]] || \
  [[ $count -eq ${WAIT_COUNT} ]]
do
    echo ">>> waiting for ${URL} to be available"
    sleep ${WAIT_TIME}
    count=$((count + 1))
done

if [[ $count -eq ${WAIT_COUNT} ]]; then
  echo ">>> Retry count exceeded. ${URL} not avilable"
  exit 1
else
  echo ">>> ${URL} is avilable"
fi

