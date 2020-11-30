round=$1
model=$2
iteramount=$3

treatments=('baseline' 'LotS' 'LitL')

for treatment in "${treatments[@]}"
do
	fdir=${treatment}_${round}
	echo $fdir

	comb_size=$(( $round*$iteramount ))

	sh $PWD/single/train-models.sh ${fdir} ${model} ${comb_size}
	sh $PWD/single/train-models.sh ${fdir}_separate ${model} ${iteramount}
	sh $PWD/single/train-models.sh ${fdir} ${model} ${comb_size} true
	sh $PWD/single/train-models.sh ${fdir}_separate ${model} ${iteramount} true
done