round=$1
model=$2

treatments=('baseline' 'LotS' 'LitL')

for treatment in "${treatments[@]}"
do
	fdir=${treatment}_${round}
	echo $fdir

	sh tokenization-and-cache.sh ${fdir} ${model}
	sh tokenization-and-cache.sh ${fdir}_separate ${model}
	sh tokenization-and-cache.sh ${fdir} ${model} true
	sh tokenization-and-cache.sh ${fdir}_separate ${model} true
	sh tokenization-and-cache.sh eval_${fdir} ${model}
	sh tokenization-and-cache.sh eval_${fdir}_separate ${model}
done