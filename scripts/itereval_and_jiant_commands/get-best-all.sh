round=$1

treatments=('baseline' 'LotS' 'LitL')

for treatment in "${treatments[@]}"
do
	fdir=${treatment}_${round}
	echo $fdir

	sh get-best.sh ${fdir}
	sh get-best.sh ${fdir}_separate
	sh get-best.sh ${fdir}_hyp
	sh get-best.sh ${fdir}_separate_hyp
done