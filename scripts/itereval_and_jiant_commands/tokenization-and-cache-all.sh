round=$1
model=$2

treatments=('baseline' 'LotS' 'LitL')

for treatment in "${treatments[@]}"
do
	fdir=${treatment}_${round}
	echo $fdir

	# sh tokenization-and-cache.sh ${fdir} ${model}
	# sh tokenization-and-cache.sh ${fdir}_separate ${model}
	# sh tokenization-and-cache.sh ${fdir} ${model} true
	# sh tokenization-and-cache.sh ${fdir}_separate ${model} true
	# sh tokenization-and-cache.sh eval_${fdir} ${model}
	# sh tokenization-and-cache.sh eval_${fdir}_separate ${model}

	for target in "${treatments[@]}"
	do
		if [ $treatment == $target ]
		then
			echo Skip $treatment $target
			continue
		fi

		echo ${treatment}_${round}-${target}_${round}

		sh tokenization-and-cache.sh ${treatment}_${round}-${target}_${round} ${model}
		sh tokenization-and-cache.sh ${treatment}_${round}_separate-${target}_${round} ${model}
	done

done