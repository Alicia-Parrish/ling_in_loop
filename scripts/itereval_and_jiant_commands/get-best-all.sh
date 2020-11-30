round=$1
model=$2

treatments=('baseline' 'LotS' 'LitL')

for treatment in "${treatments[@]}"
do
	fdir=${treatment}_${round}
	echo $fdir

	sh $PWD/single/get-best.sh ${fdir} ${model}
	sh $PWD/single/get-best.sh ${fdir}_separate ${model}
	sh $PWD/single/get-best.sh ${fdir}_hyp ${model}
	sh $PWD/single/get-best.sh ${fdir}_separate_hyp ${model}
done