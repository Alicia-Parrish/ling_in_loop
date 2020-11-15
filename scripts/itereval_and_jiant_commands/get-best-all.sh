round=$1

treatments=('baseline' 'LotS' 'LitL')

for treatment in "${treatments[@]}"
do
	fdir=${treatment}_${round}
	echo $fdir

	sh get-best.sh ${fdir}
	sh get-best.sh ${fdir}_separate
	sh get-best.sh ${fdir} true
	sh get-best.sh ${fdir}_separate true
done