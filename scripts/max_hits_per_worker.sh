#!/bin/sh

MAXHITS=10
QUALID=3C2W12C2LGZN4EMQFHW6CYO6T4FRUC #3I79FTN7D40ZECN6E5LO0NRTF2Z4EN
BLOCKQUALID=3XQ9J27GI6KR2C3EAATQ7K56T9EMHI
LISTHITS="$(aws mturk list-hits-for-qualification-type  --qualification-type-id $QUALID | jq '.HITs[].HITId')"

# while :
# do
WORKERS=()
for value in $LISTHITS
do
	temp="${value%\"}"
	temp="${temp#\"}"
	# echo $temp
	WORKERIDS="$(aws mturk list-assignments-for-hit --hit-id $temp | jq '.Assignments[].WorkerId')"
	for worker in $WORKERIDS
	do
		WORKERS+=($worker)
	done
	# echo $(echo ${WORKERS[*]} | tr ' ' '\n' | sort | uniq -c)
done

# echo ${WORKERS[*]}
echo $(echo ${WORKERS[*]} | tr ' ' '\n' | sort | uniq -c)

UNIQWORKERS="$(echo ${WORKERS[*]} | tr ' ' '\n' | sort | uniq)"

for uniqueworker in $UNIQWORKERS
do
	workercount="$(echo ${WORKERS[*]} | tr ' ' '\n' | grep -c $uniqueworker)"
	if (($workercount>$MAXHITS))
	then
		# aws mturk associate-qualification-with-worker --qualification-type-id $BLOCKQUALID --worker-id $uniqueworker
		echo $uniqueworker
	fi
done

# sleep(600)

# done
