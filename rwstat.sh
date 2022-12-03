# !/bin/bash
cd /proc 

#Percentagens: Sara Almeia 108796 - 50% & Hugo Correia 108215 - 50%

declare -A READBI  #Array para armazenar os valores iniciais de READB
declare -A WRITEBI #Array onde irá ser guardado o valor inicial dos WriteB
declare -A PID_array=() #Array onde irá ser guardado o PID de todos os processos

#------------------------------------Declaracao das variaveis----------------------------------
#Valor default da filtragem por regex '-c'
flag_c="NULL" 
#Valor default da filtragem por user '-u'
flag_u="NULL"
#Valor default do gama de pids minima '-m'
flag_m="NULL"
#Valor default do gama de pids maxima '-M'
flag_M="NULL"
#Valor default do numero de processos '-p'
flag_p="NULL"
#("" or "-r") Se a flag reverse não for acionadada,
# os processos são ordenados por ordem inversa a taxa de leitura
reverse=""
#(NULL or -w) Se a flag -w for acionada,
# os processos são ordenados por ordem inversa a taxa de escrita
flag_w="NULL" 
#data minima default '-s'
min_date="NULL"
#data maxima default '-e'
#se não for passado argumento -e com data máxima, o programa assume a data atual
max_date="NULL"
min_date_s="NULL"
max_date_s="NULL"
#associar o último argumento a uma variável chamada last para ser mais fácil de manipular e utilizar
last=${@: -1} 
n_argumentos=0 #numero de argumentos passados
n_opcoes=0 #numero de opções passadas

#regex para a flag -c
re='^[0-9]+([.][0-9]+)?$'
#------------------------------------Fim da declaracao das variaveis----------------------------------
#esta função é chamada sempre que for preciso validar se um argumento é um número inteiro
num_Int() {
    if [[ $1 =~ ^[0-9]+$ ]]; then # ^[0-9]+$ - verifica se o argumento é um número inteiro
        return 0 #retorna 0 se for um número inteiro
    else
        return 1 #retorna 1 se não for um número inteiro
    fi
}

#esta função é chamada sempre que são passadas as opções -s e/ou -e para validar o formato das datas passadas como argumentos
validate_date() { 

    #data passada como argumento
    date1=$OPTARG
    #data passada como argumento, mas formatada com o formato dado no guião do projeto
    date2=$(date +"%b %d %H:%M" -d "$date1")

    #se a data passada como argumento não for igual à mesma formatada corretamente significa que o formato é inválido
    if [ "$date1" != "$date2" ]; then
        echo "Data inválida! Formato correto 'Month Day Hour:Minute'";
        exit 1;
    fi
}

#função de validação de todos os argumentos
arguments_validation(){

    if [[ $# -lt 1 ]]; then  #se o número de argumentos for menor que 1, significa que não foi passado nenhum argumento
        echo "Número de argumentos inválido! Passe, pelo menos, 1 argumento sendo esse o sleep time."
        exit 1
    
    #verificar se o último argumento é um número inteiro
    elif ! num_Int ${@: -1}; then  #se o último argumento não for um número inteiro
        echo "O último argumento deverá ser um número inteiro correspondente ao sleep time!"
        exit 1
    fi

    while getopts ":c:s:e:u:m:M:p:rw" opt; do #verificar se os argumentos passados são válidos
        case $opt in
            c) #verificar se a flag ja foi acionada anteriormente
                if [ "$flag_c" != "NULL" ]; then
                    echo "A flag -c já foi acionada anteriormente!"
                    exit 1
                fi
                if [[ $# != $(($OPTIND-1)) ]] && ! [[ $OPTARG =~ ^-[a-zA-Z] ]] && ! [[ $OPTARG =~ $re ]] ; then #verificar que o OPTARG não é o último argumento nem começa com "-"
                    flag_c=$OPTARG #se for válido, guardar o valor do argumento na variável flag_c
                    n_argumentos=$(($n_argumentos+1)) #incrementar o número de argumentos
                    n_opcoes=$(($n_opcoes+1)) #incrementar o número de opções
                else #se não for válido
                    echo "O argumento -c nao pode ser o último argumento nem pode ser seguido de outro argumento '-#'!"
                    usage
                    exit 1         
                fi
            ;;

            s) 
                #converter a data mínima para segundos para poder comparar com a data máxima, caso esta seja passada como argumento
                if [ "$min_date" != "NULL" ]; then
                    echo "A flag -s já foi acionada anteriormente!"
                    exit 1
                fi
                min_date_s=$(date -d "$OPTARG" +%s) 
                if [[ $# != $(($OPTIND-1)) ]] && ! [[ $OPTARG =~ ^-[a-zA-Z] ]]; then #verificar que o OPTARG não é o último argumento nem começa com "-"
                    if validate_date $OPTARG; then #verificar se a data é válida através da função date
                        min_date=$OPTARG #se for válida, guardar o valor do argumento na variável min_date
                        n_argumentos=$(($n_argumentos+1)) #incrementar o número de argumentos
                        n_opcoes=$(($n_opcoes+1)) #incrementar o número de opções
                    fi
                else
                    echo "O argumento -s nao pode ser o último argumento nem pode ser seguido de outro argumento '-#'!"
                    usage #funcão criada para mostrar as opcões de argumentos válidos
                    exit 1 
                fi
                
            ;;
            
            e)
                #converter a data máxima para segundos para poder comparar com a data mínima
                if [ "$max_date" != "NULL" ]; then
                    echo "A flag -e já foi acionada anteriormente!"
                    exit 1
                fi
                max_date_s=$(date -d "$OPTARG" +%s)
                if [[ $# != $(($OPTIND-1)) ]] && ! [[ $OPTARG =~ ^-[a-zA-Z] ]]; then
                    if [[ $min_date_s -ge $max_date_s ]]; then #validar que ,caso a data máxima exista, esta é maior que a data mínima
                        echo "Data máxima inválida! A data máxima deve ser maior que a data mínima, ou não existir!"
                        usage #funcão criada para mostrar as opcões de argumentos possíveis
                        exit 1
                    else
                        if validate_date $OPTARG; then #verificar se a data é válida através da função date
                            max_date=$OPTARG #se for válida, guardar o valor do argumento na variável max_date
                            n_argumentos=$(($n_argumentos+1)) #incrementar o número de argumentos
                            n_opcoes=$(($n_opcoes+1)) #incrementar o número de opções
                        fi
                    fi
                else
                    echo "O argumento -e nao pode ser o último argumento nem pode ser seguido de outro argumento '-#'!"
                    usage
                    exit 1 
                fi
            ;;

            u)
                if [ "$flag_u" != "NULL" ]; then
                    echo "A flag -u já foi acionada anteriormente!"
                    exit 1
                fi
                if [[ $# != $(($OPTIND-1)) ]] && ! [[ $OPTARG =~ ^-[a-zA-Z] ]]; then
                        #verificar se o argumento passadon é um username válido
                        if id -u $OPTARG >/dev/null 2>&1; then
                            flag_u=$OPTARG #se for válido, guardar o valor do argumento na variável flag_u
                            n_argumentos=$(($n_argumentos+1)) #incrementar o número de argumentos
                            n_opcoes=$(($n_opcoes+1)) #incrementar o número de opções
                        else
                            echo "O argumento -u não é um username válido!"
                            usage
                            exit 1
                        fi
                    else
                    echo "O argumento -u nao pode ser o último argumento nem pode ser seguido de outro argumento '-#'!"
                    usage
                    exit 1 
                fi
            ;;

            m)
                if [ "$flag_m" != "NULL" ]; then
                    echo "A flag -m já foi acionada anteriormente!"
                    exit 1
                fi
                if [[ $# != $(($OPTIND-1)) ]] && ! [[ $OPTARG =~ ^-[a-zA-Z] ]]; then
                    if num_Int $OPTARG; then #verificar se o argumento é um número inteiro
                        flag_m=$OPTARG #se for válido, guardar o valor do argumento na variável flag_m
                        n_argumentos=$(($n_argumentos+1)) #incrementar o número de argumentos
                        n_opcoes=$(($n_opcoes+1)) #incrementar o número de opções
                    else
                        echo "O argumento -m deve ser seguido de um número inteiro!"
                        usage #funcão criada para mostrar as opcões de argumentos possíveis
                        exit 1
                    fi
                else
                    echo "O argumento -m nao pode ser o último argumento nem pode ser seguido de outro argumento '-#'!"
                    usage
                    exit 1 
                fi
            ;;

            M)
                if [ "$flag_M" != "NULL" ]; then
                    echo "A flag -M já foi acionada anteriormente!"
                    exit 1
                fi
                if [[ $# != $(($OPTIND-1)) ]] && ! [[ $OPTARG =~ ^-[a-zA-Z] ]]; then
                    if num_Int $OPTARG; then #verificar se o argumento é um número inteiro
                        if [[ $OPTARG -gt $flag_m ]]; then #verificar que o valor de gama de pids M é maior que o valor de m
                            flag_M=$OPTARG #se for válido, guardar o valor do argumento na variável flag_M
                            n_argumentos=$(($n_argumentos+1)) #incrementar o número de argumentos
                            n_opcoes=$(($n_opcoes+1)) #incrementar o número de opções
                        else
                            echo "O argumento -M deve ser maior que o argumento -m!"
                            usage
                            exit 1
                        fi
                    else
                        echo "O argumento -M deve ser seguido de um número inteiro!"
                        usage
                        exit 1
                    fi
                else
                    echo "O argumento -M nao pode ser o último argumento nem pode ser seguido de outro argumento '-#'!"
                    usage
                    exit 1 
                fi
            ;;

            p)
                if [ "$flag_p" != "NULL" ]; then
                    echo "A flag -p já foi acionada anteriormente!"
                    exit 1
                fi
                if [[ $# != $(($OPTIND-1)) ]] && ! [[ $OPTARG =~ ^-[a-zA-Z] ]]; then #verificar que o OPTARG não é o último argumento nem começa com "-"
                    if num_Int $OPTARG; then #verificar se o argumento é um número inteiro
                        flag_p=$OPTARG
                        n_argumentos=$(($n_argumentos+1)) #incrementar o número de argumentos
                        n_opcoes=$(($n_opcoes+1)) #incrementar o número de opções
                    else
                        echo "O argumento -p deve ser seguido de um número inteiro!"
                        usage
                        exit 1
                    fi
                else
                    echo "O argumento -p nao pode ser o último argumento nem pode ser seguido de outro argumento '-#'!"
                    usage
                    exit 1
                fi
            ;;

            r)
                if [ "$reverse" != "" ]; then
                    echo "A flag -r já foi acionada anteriormente!"
                    exit 1
                fi
                reverse="-r" #se o argumento -r for passado, guardar o valor "-r" na variável reverse e o programa vai ordenar os resultados por ordem normal da taxa de leitura
                n_opcoes=$(($n_opcoes+1)) #incrementar o número de opções
            ;;

            w)
                if [ "$flag_w" != "NULL" ]; then
                    echo "A flag -w já foi acionada anteriormente!"
                    exit 1
                fi
                flag_w="-w" #se a fkag -w for passada, guardar o valor "-w" na variável flag_w e o programa vai ser ordenado tendo por base a coluna dos WriteB
                n_opcoes=$(($n_opcoes+1)) #incrementar o número de opções
            ;;

            *) #caso o argumento não seja válido
                echo "Opção inválida: -$OPTARG" >&2
                usage
                exit 1
            ;;
        esac
    done
    if [[ $# != $(($n_argumentos+$n_opcoes+1)) ]]; then
        echo "Numero inválido de argumentos!"
        usage
        exit 1
    fi
}

listar_processos(){
    printf "%-20s\t\t %8s\t\t %10s\t %10s\t %9s\t %10s\t %10s %16s\n" "COMM" "USER" "PID" "READB" "WRITEB" "RATER" "RATEW" "DATE"   #imprimir cabeçalho

    for pid in $(ps -e -o pid=); do #percorrer todos os pids existentes no diretório proc
        #verificar se os ficheiros io, status e comm são readables
        if [[ -r /proc/$pid/io && -r /proc/$pid/status && -r /proc/$pid/comm ]]; then
            #guardar o valor de rchar do ficheiro io do pid em questão na posição do pid no array READBI
            READBI[$pid]=`cat $pid/io | grep rchar | awk '{print $2}'`
            #guardar o valor de wchar do ficheiro io do pid em questão na posição do pid no array WRITEBI
            WRITEBI[$pid]=`cat $pid/io | grep wchar | awk '{print $2}'`

        fi
    done
    sleep $last #esperar o tempo que o utilizador passou como argumento para o programa
    for pid in $(ps -e -o pid=); do #percorrer todos os pids existentes no diretório proc outra vez
        if [[ -r /proc/$pid/io && -r /proc/$pid/status && -r /proc/$pid/comm ]]; then #verificar se os ficheiros io, status e comm são readables
            if [[ ! ${!READBI[*]} =~ "${pid}" ]]; then
                continue
            fi

            READBF=`cat $pid/io | grep rchar | awk '{print $2}'`  #guardar o valor de rchar do ficheiro io do pid em questão numa variável
            WRITEBF=`cat $pid/io | grep wchar | awk '{print $2}'` #guardar o valor de wchar do ficheiro io do pid em questão numa variável
            #calcular a diferenca entre o READBF e o READBI e guardar o valor na posição do pid no array READB
            READB[$pid]=$(($READBF-${READBI[$pid]}))
            #calcular a diferenca entre o WRITEBF e o WRITEBI e guardar o valor na posição do pid no array WRITEB
            WRITEB[$pid]=$(($WRITEBF-${WRITEBI[$pid]}))

            COMM=$(cat $pid/comm | tr -s ' ' '_') #guardar o valor de comm do ficheiro comm do processo em questão numa variável

            USER=$(ps -u -p $pid | awk '{print $1}' | tail -1) #guarda o valor do user do processo em questão numa variável
            #Data de criacao do processo
            process_date=$(ls -ld /proc/$pid)
            process_date=$(echo $process_date | awk '{ print $6" "$7" "$8}') #guardar a data de criação do processo no formato desejado numa variável
            #calcular a taxa de leitura usando a fórmula dada no enunciado (READBF - READBI) / last
            RATER=$(echo "scale=2; ($READBF - ${READBI[$pid]}) / $last" | bc)
            #calcular a taxa de escrita usando a fórmula dada no enunciado (WRITEBF - WRITEBI) / last
            RATEW=$(echo "scale=2; ($WRITEBF - ${WRITEBI[$pid]}) / $last" | bc)
            #Guarda o processo em questão num array associativo com o pid como chave
            #Cada valor é guardado numa coluna separada por tabs e formatada para que fique igual ao que foi pedido no enunciado
            PID_array[$pid]=$(printf "\n%-20s\t\t %8s\t\t %10s\t %10s\t %9s\t %10s\t %10s %16s\n" "$COMM" "$USER" "$pid" "${READB[$pid]}" "${WRITEB[$pid]}" "$RATER" "$RATEW" "$process_date") 
        fi
    done
}

PID_filter(){
    for pid in "${!PID_array[@]}"; do #percorrer todos os pids existentes no array PID_array
        #Acede ao valor COMM associado ao pid em questão e guarda-o numa variável
        COMM=$(echo ${PID_array[$pid]} | awk '{print $1}')
        #Acede ao valor USER associado ao pid em questão e guarda-o numa variável
        USER=$(echo ${PID_array[$pid]} | awk '{print $2}') 
        #Acede ao valor PID associado ao pid em questão e guarda-o numa variável
        PID=$(echo ${PID_array[$pid]} | awk '{print $3}')
        #Acede ao valor READB associado ao pid em questão e guarda-o numa variável
        READB=$(echo ${PID_array[$pid]} | awk '{print $4}')
        #Acede ao valor WRITEB associado ao pid em questão e guarda-o numa variável
        WRITEB=$(echo ${PID_array[$pid]} | awk '{print $5}')
        #Acede ao valor RATER associado ao pid em questão e guarda-o numa variável
        RATER=$(echo ${PID_array[$pid]} | awk '{print $6}')
        #Acede ao valor RATEW associado ao pid em questão e guarda-o numa variável
        RATEW=$(echo ${PID_array[$pid]} | awk '{print $7}')
        #Acede ao valor DATE associado ao pid em questão e guarda-o numa variável
        DATE=$(echo ${PID_array[$pid]} | awk '{print $8" "$9" "$10}')
        #Data do processo mas em segundos
        DATE_s=$(date -d "$DATE" +%s)

        
        #Compara o valor de COMM com o valor de COMM passado como argumento
        if [[ $flag_c != "NULL" ]]; then #se o utilizador passou o argumento -c
            if ! [[ $COMM =~ $flag_c ]]; then #se o valor de COMM não contém o valor de COMM passado como argumento
                unset PID_array[$pid] #remove o pid do array PID_array
            fi
        fi
        #Compara o valor de USER com o valor de USER passado como argumento
        if [[ $flag_u != "NULL" ]]; then #se o utilizador passou o argumento -u
            if ! [[ $USER =~ $flag_u ]]; then  #se o valor de USER não contém o valor de USER passado como argumento
                unset PID_array[$pid] #remove o pid do array PID_array
            fi
        fi
        if [[ $flag_m != "NULL" || $flag_M != "NULL" ]]; then #se o utilizador passou o argumento -m ou -M
            if [[ $flag_m != "NULL" && $flag_M != "NULL" ]]; then #se o utilizador passou os argumentos -m e -M
                if [[ $pid -lt $flag_m || $pid -gt $flag_M ]]; then #verificar se o PID está fora dos valores de -m e -M
                    unset PID_array[$pid] #remove o pid do array PID_array
                fi
            elif [[ $flag_m != "NULL" && $flag_M == "NULL" ]]; then #se o utilizador passou o argumento -m
                if [[ $pid -lt $flag_m ]]; then #verificar se o PID está fora do valor de -m
                    unset PID_array[$pid] #remove o pid do array PID_array
                fi
            elif [[ $flag_m == "NULL" && $flag_M != "NULL" ]]; then #se o utilizador passou o argumento -M
                if [[ $pid -gt $flag_M ]]; then #verificar se o PID está fora do valor de -M
                    unset PID_array[$pid] #remove o pid do array PID_array
                fi
            fi
        fi
        if [[ $min_date != "NULL" ]]; then #se o utilizador passou o argumento -d
            if [[ $DATE_s -lt $min_date_s ]]; then #verificar se a data do processo está fora do valor de -d
                unset PID_array[$pid] #remove o pid do array PID_array
            fi
        fi
        if [[ $max_date != "NULL" ]]; then #se o utilizador passou o argumento -D
            if [[ $DATE_s -gt $max_date_s ]]; then #verificar se a data do processo está fora do valor de -D
                unset PID_array[$pid] #remove o pid do array PID_array
            fi
        fi
    done
}

#função chamada caso o argumento seja inválido
#imprime todas os argumentos possíveis
#[-cseumMprw]
usage() {
    echo " $0 opções:" 
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

sort_process(){
    if [[ $flag_p != "NULL" ]]; then #se o utilizador passou o argumento -p
        if [[ $reverse == "-r" ]]; then #se o utilizador passou o argumento -r
            if [[ $flag_w == "-w" ]]; then #se o utilizador passou o argumento -w
                printf "%s" "${PID_array[@]}" | sort -k7 -n | head -n $(($flag_p+1)) #ordena o array PID_array pelo valor de WRITEB e imprime os primeiros $flag_p processos
            else
                printf "%s" "${PID_array[@]}" | sort -k6 -n | head -n $(($flag_p+1)) #ordena o array PID_array pelo valor de RATER e imprime os primeiros $flag_p processos
            fi  
        else
            if [[ $flag_w == "-w" ]]; then #se o utilizador passou o argumento -w
                printf "%s" "${PID_array[@]}" | sort -k7 -n -r | head -n $flag_p #ordena o array PID_array pelo valor de WRITEB e imprime os primeiros $flag_p processos
            else
                printf "%s" "${PID_array[@]}" | sort -k6 -n -r | head -n $flag_p #ordena o array PID_array pelo valor de RATER e imprime os primeiros $flag_p processos
            fi
        fi
    else #se o utilizador não passou o argumento -p
        if [[ $reverse == "-r" ]]; then #se o utilizador passou o argumento -r
            if [[ $flag_w == "-w" ]]; then #se o utilizador passou o argumento -w
                printf "%s" "${PID_array[@]}" | sort -k7 -n #ordena o array PID_array pelo valor de WRITEB
            else
                printf "%s" "${PID_array[@]}" | sort -k6 -n #ordena o array PID_array pelo valor de RATER
            fi  
        else
            if [[ $flag_w == "-w" ]]; then #se o utilizador passou o argumento -w
                printf "%s" "${PID_array[@]}" | sort -k7 -n -r #ordena o array PID_array pelo valor de WRITEB
            else
                printf "%s" "${PID_array[@]}" | sort -k6 -n -r #ordena o array PID_array pelo valor de RATER
            fi
        fi
    fi    
}

arguments_validation "$@" #chama a função arguments_validation passando todos os argumentos passados pelo utilizador
listar_processos #chama a função listar_processos
PID_filter  #chama a função PID_filter
sort_process  #chama a função sort_process
