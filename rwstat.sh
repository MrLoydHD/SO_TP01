# !/bin/bash
cd /proc 

declare -A READBI
declare -A READBF
declare -A WRITEBI
declare -A WRITEBF


sort_p=1
flag_c=0
flag_u=0
flag_m=0
flag_M=0
flag_p="null"
min_date=0
max_date=0 
#data atual
Date_max=$(date +%s)
Date_min="null"

#função chamada para verificar se o argumento é um número inteiro
num_Int() {
    if [[ $1 =~ ^[0-9]+$ ]]; then
        return 0
    else
        return 1
    fi
}

read_io(){
    for pid in ${PID_array[@]}; do
        if [ -e $pid/io ]; then
         # Leitura dos valores rchar e wchar obtendo apenas o valor numerico
            READBI[$pid]=`cat $pid/io | grep rchar | awk '{print $2}'`
            WRITEBI[$pid]=`cat $pid/io | grep wchar | awk '{print $2}'`       
        fi
    done
    sleep $last
    for pid in ${PID_array[@]}; do
        if [ -e $pid/io ]; then
            READBF[$pid]=`cat $pid/io | grep rchar | awk '{print $2}'`
            WRITEBF[$pid]=`cat $pid/io | grep wchar | awk '{print $2}'`
        fi
    done
    # for pid in ${PID_array[@]}; do
    #     if [ ! -e $pid/io ]; then
    #         unset READBI[$pid]
    #         unset WRITEBI[$pid]
    #     fi
    # done
}

listar_processos(){
    echo A escrever no ficheiro...

    counter=1
    for pid in ${PID_array[@]}; do

        if test -f "/proc/$pid/io"; then
            if [ -e $pid/io ]; then
                if [[ $counter == $((flag_p+1)) ]]; then
                    echo "Numero maximo de processos atingido"
                    break
                fi
            fi

            READBF=`cat $pid/io | grep rchar | awk '{print $2}'`
            WRITEBF=`cat $pid/io | grep wchar | awk '{print $2}'`

            COMM=$(cat $pid/comm | tr -s ' ' '_')
            #get user of the process
            USER=$(ps -u -p $PID | awk '{print $1}' | tail -1) #ter atencao
            #get creation date of the process
            startDate=$(ls -ld /proc/$pid)
            startDate=$(echo $process_date | awk '{ print $6" "$7" "$8}') #falta validar
            #rate of read using READBI and READBI of the process and sleep time
            RATER=$(echo "scale=2; ($READBF - ${READBI[$pid]}) / $last" | bc)
            #rate of write using WRITEBI and WRITEBF of the process and sleep time
            RATEW=$(echo "scale=2; ($WRITEBF - ${WRITEBI[$pid]}) / $last" | bc)
            #verify if seconds_Date is a number
            if [[ -e $flag_p ]]; then
                counter=$((counter+1))
            fi
        fi 
    done | sort -n -k $sort_p $sort_reverse
    if [[ -z $flag_p ]]; then
        echo concluido!
    fi
}


#função chamada caso o argumento seja inválido
#imprime todas os argumentos possíveis
#[-cseumMprw]
usage() {
    echo " $0 usage:" 
    echo "      -c : filtra por expressão regular"
    echo "      -s : data mínima para início do processo"
    echo "      -e : data máxima para início do processo"
    echo "      -u : seleção dos processos através do user name"
    echo "      -m -M : gama de pids"
    echo "      -p : número de processos a visualizar"
    echo "      -r : ordenação da tabela pela ordem inversa"
    echo "      -w : ordenação da tabela por valores escritos"
    exit 1
}

    #guardar o último argumento numa variável
    last=${@: -1}

    #validar número mínimo de argumentos
    if [[ $# -lt 1 ]]; then 
        echo "Número de argumentos inválido! Passe, pelo menos, 1 argumento."
    
    #verificar se o último argumento é um número inteiro
    elif ! num_Int ${@: -1}; then
        echo "O último argumento deverá ser um número inteiro!"
    fi


    while getopts ":c:s:e:u:m:M:p:rw" option; do
        case ${option} in
                    #seleção dos processos a visualizar
                    c )
                        flag_c=$OPTARG;
                    ;;

                    #especificação do período temporal
                    s ) 
                        Data_min=$OPTARG;  
                        
                    ;;
                    e )
                        Data_max=$OPTARG;
                    ;;

                    #seleção dos processos realizada através do
                    u ) 
                        flag_u=$OPTARG;
                    ;;
                    m ) 
                        if num_Int $OPTARG; then
                            flagm=$OPTARG
                        else
                            echo "O argumento -m deve ser seguido de um número inteiro!"
                            exit 1
                        fi                    
                    ;;

                    M ) 
                        if num_Int $OPTARG; then
                            if [[ $OPTARG -gt $flagm ]]; then
                                flagM=$OPTARG
                            else
                                echo "O argumento -M deve ser maior que o argumento -m!"
                                exit 1
                            fi
                        else
                            echo "O argumento -M deve ser seguido de um número inteiro!"
                            exit 1
                        fi
                    ;;

                    p )
                        flag_p=$OPTARG;
                        if ! num_Int $OPTARG; then
                            echo "O argumento -p deve ser seguido de um número inteiro!"
                            exit 1
                        fi
                    ;;

                    #alterar a ordenação da tabela
                    r )
                        sort_reverse="-r";
                    ;;
                    
                    w )
                        #sort on write values
                        if [ $sort_p -ne 1 ]; then
                            echo "Multiplos sort não suportados"
                        fi
                        sort_p=5;
                    ;;
                    
                    ?)
                        usage
                    ;;
        esac
    done
    #-----------------------------Lista de PIDS----------------------------

    PID_array=()
    PID_array_c=() 
    PID_array_u=()
    PID_array_e=()
    PID_array_m=()

    min_date=$(date -d "${Data_min}" +"%s")
    max_date=$(date -d "${Data_max}" +"%s")



    for i in $(ps -e -o pid=); do 
        basename_i="$(basename $i)"
        if num_Int $basename_i; then 
            if [[ -f "$i/io" && -f "$i/status" && -f "$i/comm" ]]; then #verificar se é um processo
                if [[ -r "/$i/io" && -r "/$i/status" && -r "/$i/comm" && -r "/proc/$basename_i" ]]; then #verificar se é readable

                    PID_array+=($basename_i)

                    #todas estas listas são criadas para facilitar a ordenação, no sentido em que se pretende retirar da lista de PIDS os que não satisfazem os critérios de seleção 

                    #lista com os PIDs dos processos que nao correspondem ao critério -c
                        if num_Int $basename_i ; then
                            COMM=$(cat $i/comm | tr -d ' ')
                            if ! [[ $COMM =~ $flag_c ]]; then
                                PID_array_c+=($basename_i)
                            fi
                        fi
                    #lista com os PIDs dos processos que nao correspondem ao critério -s e -e
                        startDate=$(ls -ld /proc/$i)
                        seconds_Date=$(date -d $startDate +%s)
                        startDate=$(echo $process_date | awk '{ print $6" "$7" "$8}') #falta validar
                        #startDate=$(date +"%b %d %H:%M" -d "$startDate")
                        if [[ $seconds_Date -lt $min_date || $seconds_Date -gt $max_date ]]; then 
                            PID_array_e+=($basename_i)
                        fi
                        #verificar se a data esta no formato correto - TODO

                    #lista com os PIDs dos processos que correspondem ao critério -u
                        if num_Int $basename_i ; then
                            #username do processo
                            USER=$(ps -o -p $basename_i user | tail -1)
                            echo $USER
                            if ! [[ $USER =~ $flag_u ]]; then
                                PID_array_u+=($basename_i)
                            fi             
                        fi
                    #lista com os PIDs dos processos que correspondem ao critério -m e -M
                        if num_Int $basename_i ; then
                            if [[ flag_m != 0 || flag_M != 0 ]]; then
                                if [[ flag_m != 0 && flag_M != 0 ]]; then
                                    if [[ $i -lt $flag_m && $i -gt $flag_M ]]; then #verificar se o PID está fora dos valores de -m e -M
                                        PID_array_m+=($basename_i)
                                    fi
                                elif [[ flag_m != 0 && flag_M == 0 ]]; then
                                    if [[ $i -lt $flag_m ]]; then
                                        PID_array_m+=($basename_i)  
                                    fi
                                elif [[ flag_m == 0 && flag_M != 0 ]]; then
                                    if [[ $i -gt $flag_M ]]; then
                                        PID_array_m+=($basename_i)
                                    fi
                                fi

                            fi
                        fi
                fi
            fi
        fi
    done

    remove_pids=()
    remove_pids=( "${PID_array_c[@]}" "${PID_array_u[@]}" "${PID_array_e[@]}" "${PID_array_m[@]}" )

    #remover os PIDs que não satisfazem os critérios de seleção retirando os duplicados
    for i in "${remove_pids[@]}"; do
        for k in "${!PID_array[@]}"; do
            if [[ ${PID_array[k]} = $i ]]; then
                unset 'PID_array[k]'
            fi
        done
    done

    read_io
    printf '%-20s\t\t %8s\t\t %10s\t %10s\t %9s\t %10s\t %10s %16s\n' "COMM" "USER" "PID" "READB" "WRITEB" "RATER" "RATEW" "DATE"
    listar_processos
