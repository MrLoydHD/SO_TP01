#!/bin/bash

if [[ $# = 0 ]]
then
	echo Tem que passar, pelo menos, um argumento \(s\).
	exit
else
	echo A validar os argumentos...
	
	for last; do true; done	# $last is the last argument passed to the script (which is always s)
	
	# arg after -p must be a number
	for ((i=0; i<="$#"; i++))
	do
		if [[ "${!i}" == "-p" ]]; then
			i=$((i+1))
			if ! [[ "${!i}" =~ ^[0-9]+$ ]]; then
				echo Argumento de -p inválido! Deve ser um número.
				exit
			fi
		elif [[ "${!i}" == "-s" ]]; then
			i=$((i+2))
			if [[ "${!i}" != "-e" ]]; then
				echo Definição do período temporal inválida! Tem que definir uma data máxima.
				exit
			fi
		fi
	done
	
	PIDarray=()	# array de todos os PIDs
	PIDarrayC=()
	PIDarrayU=()
	PIDarrayS=()
	COMMarray=() # array de todos os command names correspondentes
	
	flagC=0
	flagU=0
	flagS=0
	flagM=0
	flagT=0
	flagD=0
	flagW=0
	flagR=0
	
	while getopts "c:u:s:e:p:mtdwr" option; do
		case ${option} in
		c ) #For option c
			flagC=1
			for i in $(ls /proc) # para todas as pastas/ficheiros em /proc
			do
				if test -f "/proc/$i/io"; then
					if [ -r "/proc/$i/status" ]; then
						if [ -r "/proc/$i/io" ]; then
							if [[ $i =~ ^[0-9]+$ ]]	# se o nome da pasta for um inteiro...
							then
								COMM=$(grep Name /proc/$i/status | cut -d ":" -f2)
								COMM=$(echo $COMM)
								
								if [[ $COMM =~ ^$OPTARG$ ]]; then
									PIDarrayC+=($i)
								fi
							fi
						fi
					fi
				fi
			done
		;;
		u ) #For option u
			flagU=1
			for i in $(ls /proc)
			do
				if test -f "/proc/$i/io"; then
					if [ -r "/proc/$i/status" ]; then
						if [ -r "/proc/$i/io" ]; then
							if [[ $i =~ ^[0-9]+$ ]]
							then
								USER=$(ps -u -p $i | awk '{print $1}' | tail -1)
								if [[ $USER == $OPTARG ]]; then
									PIDarrayU+=($i)
								fi
							fi
						fi
					fi
				fi
			done
		;;
		s ) #For option s
			flagS=1
			minDate=$OPTARG
		;;
		e ) #For option e
			maxDate=$OPTARG
			
			DATE1=$(echo $maxDate | cut -d " " -f1 -)
			DATE2=$(echo $maxDate | cut -d " " -f2 -)
			DATE3=$(echo $maxDate | cut -d " " -f3 -)
			
			minDateNum=""
			maxDateNum=""
			months=("0" "Jan" "Feb" "Mar" "Apr" "May" "Jun" "Jul" "Aug" "Sep" "Oct" "Nov" "Dec")
			for m in ${!months[@]}
			do
				if [[ "$(echo $minDate | cut -d " " -f1 -)" == "${months[$m]}" ]]; then
					day=$(echo $minDate | cut -d " " -f2 -)
					hour=$(echo $minDate | cut -d " " -f3 -)
					minDateNum="$minDateNum$m-$day $hour"
				fi
				if [[ "$(echo $maxDate | cut -d " " -f1 -)" == "${months[$m]}" ]]; then
					day=$(echo $maxDate | cut -d " " -f2 -)
					hour=$(echo $maxDate | cut -d " " -f3 -)
					maxDateNum="$maxDateNum$m-$day $hour"
				fi
			done
			
			for i in $(ls /proc)
			do
				if test -f "/proc/$i/io"; then
					if [ -r "/proc/$i/status" ]; then
						if [ -r "/proc/$i/io" ]; then
							if [[ $i =~ ^[0-9]+$ ]]
							then
								DATE1=$(ps -p $i -wo lstart | grep -v STARTED | cut -d " " -f2 -)
								DATE2=$(ps -p $i -wo lstart | grep -v STARTED | cut -d " " -f4 -)
								if [[ ! $DATE2 =~ ^[0-9]+$ ]]; then
									DATE2=$(ps -p $i -wo lstart | grep -v STARTED | cut -d " " -f3 -)
								fi
								DATE3=$(ps -p $i -wo lstart | grep -v STARTED | cut -d " " -f5 -)
								DATENum=""
								
								for m in ${!months[@]}
								do
									if [[ "$DATE1" == "${months[$m]}" ]]; then
										DATENum="$DATENum$m-$DATE2 $DATE3"
									fi
								done
								
								if [[ "$DATENum" > "$minDateNum" ]] ;
								then
									if [[ "$DATENum" < "$maxDateNum" ]] ;
									then
										PIDarrayS+=($i)
									fi
								fi
							fi
						fi
					fi
				fi
			done
			
		;;
		m ) #For option m
			flagM=1
		;;
		t ) #For option t
			flagT=1
		;;
		d ) #For option d
			flagD=1
		;;
		w ) #For option w
			flagW=1
		;;
		p ) #For option p
			stopper=$OPTARG
		;;
		r ) #For option r
			flagR=1
		esac
	done
	
	# DEFINIÇÃO DE PIDarray
	# se não tivermos usado -c, -u ou -s/-e, então PIDarray contém todos os PIDs da pasta proc
	if [[ "$flagC" == "0" && "$flagU" == "0" && "$flagS" == "0" ]]; then
		for i in $(ls /proc) # para todas as pastas/ficheiros em /proc
		do
			if test -f "/proc/$i/io"; then
				if [ -r "/proc/$i/status" ]; then
					if [ -r "/proc/$i/io" ]; then
						if [[ $i =~ ^[0-9]+$ ]]	# se o nome da pasta for um inteiro...
						then
								PIDarray+=($i)
						fi
					fi
				fi
			fi
		done
	# se usámos apenas -c, ou apenas -u, ou apenas -s/-e, PIDarray vai conter todos os PIDs de PIDarrayC, ou PIDarrayU, ou PIDarrayS (respetivamente)
	elif [[ "$flagC" == "1" && "$flagU" == "0" && "$flagS" == "0" ]]; then
		PIDarray=${PIDarrayC[@]}
	elif [[ "$flagC" == "0" && "$flagU" == "1" && "$flagS" == "0" ]]; then
		PIDarray=${PIDarrayU[@]}
	elif [[ "$flagC" == "0" && "$flagU" == "0" && "$flagS" == "1" ]]; then
		PIDarray=${PIDarrayS[@]}
	# se usámos uma combinação de -c, -u e -s/-e, queremos apenas os PIDs que estão em todos os PIDarrays das flags acionadas (união de conjuntos); fazemos um array geral que junta tudo e retiramos os duplicados
	else
		allPIDarray=()
		if [[ "$flagC" == "1" ]]; then
			allPIDarray=("${allPIDarray[@]}" "${PIDarrayC[@]}")
		fi
		if [[ "$flagU" == "1" ]]; then
			allPIDarray=("${allPIDarray[@]}" "${PIDarrayU[@]}")
		fi
		if [[ "$flagS" == "1" ]]; then
			allPIDarray=("${allPIDarray[@]}" "${PIDarrayS[@]}")
		fi

		for a in ${!allPIDarray[@]}
		do
			for b in ${!allPIDarray[@]}
			do
				bCounter=0
				if [[ "$b" > "$a" ]]; then
					if [[ ("${allPIDarray[$a]}" == "${allPIDarray[$b]}") ]]; then
						bCounter=$(($bCounter+1))
						if [[ $((flagC+flagU+flagS)) == 3 && "$bCounter" == "2" ]]; then
							PIDarray+=(${allPIDarray[$a]})
						elif [[ $((flagC+flagU+flagS)) == 2 && "$bCounter" == "1" ]]; then
							PIDarray+=(${allPIDarray[$a]})
						fi
					fi
				fi
			done
		done
	fi
	
	# PARTE PRINCIPAL
	counter=1

	if [[ $((flagM+flagT+flagD+flagW)) > 1 ]]; then
		echo Argumentos de ordenação inválidos!
		exit
	fi
	
	echo A escrever no ficheiro...
	
	install -b -m 755 /dev/null data.txt # criar ficheiro com permissões de leitura, escrita e execução
	echo COMM USER PID MEM RSS READB WRITEB RATER RATEW DATE >> data.txt
	
	## RATES
	declare -A READBI
	declare -A READBF
	declare -A WRITEBI
	declare -A WRITEBF
	for j in ${PIDarray[@]}
	do
		READBI[$j]=$(cat /proc/$j/io | grep rchar /proc/$j/io | cut -d ":" -f2 -)
		WRITEBI[$j]=$(grep wchar /proc/$j/io | cut -d ":" -f2 -)
	done
	sleep $last
	for j in ${PIDarray[@]}
	do
		READBF[$j]=$(cat /proc/$j/io | grep rchar /proc/$j/io | cut -d ":" -f2 -)
		WRITEBF[$j]=$(grep wchar /proc/$j/io | cut -d ":" -f2 -)
	done

	for j in ${PIDarray[@]}
	do
		#echo PID $j
		if test -f "/proc/$j/status"; then
			if [[ ! -z $stopper ]]; then
				if [[ $counter == $((stopper+1)) ]]; then
					echo Concluído!
					echo
					break
				fi
			fi
			
			PID=$j	# ...então esse int é o pid
			COMM=$(grep Name /proc/$PID/status | cut -d ":" -f2)
			if [[ "$COMM" =~ \ |\' ]]; then
				COMM=${COMM// /_}
			fi
			USER=$(ps -u -p $PID | awk '{print $1}' | tail -1)
			MEM=$(grep VmSize /proc/$PID/status | cut -d ":" -f2 - | cut -d "k" -f1)
			if [ -z $MEM ]
			then
				continue
			fi
			RSS=$(grep VmRSS /proc/$PID/status | cut -d ":" -f2 - | cut -d "k" -f1)
			if [ -z $RSS ]
			then
				continue
			fi
			READB=$(grep rchar /proc/$PID/io | cut -d ":" -f2 -)
			WRITEB=$(grep wchar /proc/$PID/io | cut -d ":" -f2 -)
			DATE1=$(ps -p $PID -wo lstart | grep -v STARTED | cut -d " " -f2 -)
			DATE2=$(ps -p $PID -wo lstart | grep -v STARTED | cut -d " " -f4 -)
			if [[ ! $DATE2 =~ ^[0-9]+$ ]]; then
				DATE2=$(ps -p $i -wo lstart | grep -v STARTED | cut -d " " -f3 -)
			fi
			DATE3=$(ps -p $PID -wo lstart | grep -v STARTED | cut -d " " -f5 -)
			
			RATER=$( echo "scale=2;var1=${READBF[$PID]}; var2=${READBI[$PID]}; var3=$last; res=(var1-var2)/var3; res" | bc -l )
			RATEW=$( echo "scale=2;var1=${WRITEBF[$PID]}; var2=${WRITEBI[$PID]}; var3=$last; res=(var1-var2)/var3; res" | bc -l )
			
			echo $COMM $USER $PID $MEM $RSS $READB $WRITEB $RATER $RATEW $DATE1 $DATE2 $DATE3 >> data.txt
			if [[ ! -z $stopper ]]; then
				counter=$((counter+1))
			fi
		fi
	done
	if [[ -z $stopper ]]; then
		echo Concluído!
		echo
	fi
fi

### ------IMPRIMIR------
# COM ORDENAÇÃO
if [[ "$flagM" == "1" || "$flagT" == "1" || "$flagD" == "1" || "$flagW" == "1" ]]; then
	declare -A dataArray
	dataCounter=0
	while read line; do
		if [[ "$flagM" == "1" ]]; then
			fileDATA=$(echo $line | cut -d " " -f4 -) # get MEM
		elif [[ "$flagT" == "1" ]]; then
			fileDATA=$(echo $line | cut -d " " -f5 -) # get RSS
		elif [[ "$flagD" == "1" ]]; then
			fileDATA=$(echo $line | cut -d " " -f8 -) # get RATER
		elif [[ "$flagW" == "1" ]]; then
			fileDATA=$(echo $line | cut -d " " -f9 -) # get RATEW
		fi
		if [[ $fileDATA == "MEM" || $fileDATA == "RSS" || $fileDATA == "RATER" || $fileDATA == "RATEW" ]]; then
			dataCounter=$((dataCounter+1))
			continue
		fi
		dataArray[$dataCounter]=$fileDATA
		dataCounter=$((dataCounter+1))
	done < data.txt
	indArray=($(for k in "${!dataArray[@]}"
				do
					echo ${dataArray[$k]}':'$k
				done | sort -n | cut -d ":" -f2 -))
				
	if [[ "$flagR" == "1" ]]; then
	# REVERSE ARRAY ORDER
		min=0
		max=$(( ${#indArray[@]} -1 ))
		while [[ min -lt max ]]
		do
			# Swap current first and last elements
			x="${indArray[$min]}"
			indArray[$min]="${indArray[$max]}"
			indArray[$max]="$x"
			# Move closer
			(( min++, max-- ))
		done
	fi
	
	tableHeader="%-20s %-8s %-8s %-12s %-12s %-10s %-10s %-11s %-11s %-3s %-3s %-3s\n"
	printf "$tableHeader" "COMM" "USER" "PID" "MEM" "RSS" "READB" "WRITEB" "RATER" "RATEW" "DATE"
	for i in "${indArray[@]}"
	do
		lineCounter=0
		while read line; do
			if [[ $i == $lineCounter ]]; then
				printf "$tableHeader" $line
				break;
			fi
			lineCounter=$((lineCounter+1))
		done < data.txt
	done
	
# SEM ORDENAÇÃO
else
	tableHeader="%-20s %-8s %-8s %-12s %-12s %-10s %-10s %-11s %-11s %-3s %-3s %-3s\n"
	printf "$tableHeader" "COMM" "USER" "PID" "MEM" "RSS" "READB" "WRITEB" "RATER" "RATEW" "DATE"
	sed 1d data.txt | while read d
	do
		printf "$tableHeader" $d
	done | sort
fi
