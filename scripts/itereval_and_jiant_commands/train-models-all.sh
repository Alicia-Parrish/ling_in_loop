round=$1
model=$2
iteramount=$3

treatments=('baseline' 'LotS' 'LitL')

for treatment in "${treatments[@]}"
do
	fdir=${treatment}_${round}
	echo $fdir

	comb_size=$(( $round*$iteramount ))

	sh train-models.sh ${fdir} ${model} ${comb_size}
	sh train-models.sh ${fdir}_separate ${model} ${iteramount}
	sh train-models.sh ${fdir} ${model} ${comb_size} true
	sh train-models.sh ${fdir}_separate ${model} ${iteramount} true
done