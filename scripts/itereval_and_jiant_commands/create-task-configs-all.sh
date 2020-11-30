round=$1

treatments=('baseline' 'LotS' 'LitL')

for treatment in "${treatments[@]}"
do
	fdir=${treatment}_${round}
	echo $fdir

	sh $PWD/single/create-task-configs.sh ${fdir}
	sh $PWD/single/create-task-configs.sh ${fdir}_separate
	sh $PWD/single/create-task-configs.sh ${fdir} true
	sh $PWD/single/create-task-configs.sh ${fdir}_separate true
done

sh $PWD/single/create-cross-configs.sh ${round}