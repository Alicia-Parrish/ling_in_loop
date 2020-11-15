round=$1

treatments=('baseline' 'LotS' 'LitL')

for treatment in "${treatments[@]}"
do
	fdir=${treatment}_${round}
	echo $fdir

	sh create-task-configs.sh ${fdir}
	sh create-task-configs.sh ${fdir}_separate
	sh create-task-configs.sh ${fdir} true
	sh create-task-configs.sh ${fdir}_separate true
done