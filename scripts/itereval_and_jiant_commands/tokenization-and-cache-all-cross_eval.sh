round=$1
model=$2

treatments=('baseline' 'LotS' 'LitL')
sample='cross_eval'
splits=('0.1' '0.2' '0.3' '0.4' '0.5' '0.6' '0.7' '0.8' '0.9' '1.0')

for treatment in "${treatments[@]}"
do
	for split in "${splits[@]}"
	do
		fdir=${treatment}_${round}
		echo $fdir
		echo ${sample}/${split}

		sh $PWD/single/tokenization-and-cache-sampled.sh ${fdir} ${sample}/${split} ${model}
		sh $PWD/single/tokenization-and-cache-sampled.sh ${fdir}_separate ${sample}/${split} ${model}
		sh $PWD/single/tokenization-and-cache-sampled.sh ${fdir} ${sample}/${split} ${model} true
		sh $PWD/single/tokenization-and-cache-sampled.sh ${fdir}_separate ${sample}/${split} ${model} true
		sh $PWD/single/tokenization-and-cache-sampled.sh eval_${fdir} ${sample}/${split} ${model}
		sh $PWD/single/tokenization-and-cache-sampled.sh eval_${fdir}_separate ${sample}/${split} ${model}
		sh $PWD/single/tokenization-and-cache-sampled.sh mnlieval_${fdir} ${sample}/${split} ${model}
		sh $PWD/single/tokenization-and-cache-sampled.sh mnlieval_${fdir}_separate ${sample}/${split} ${model}
		sh $PWD/single/tokenization-and-cache-sampled.sh anlieval_${fdir} ${sample}/${split} ${model}
		sh $PWD/single/tokenization-and-cache-sampled.sh anlieval_${fdir}_separate ${sample}/${split} ${model}
	done
done