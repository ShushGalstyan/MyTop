#!/bin/bash
clock_ticks=$(getconf CLK_TCK)
cat /dev/null > Top.PS ; cd /proc
total_count=0; Sleeping=0 ; Stopped=0; Running=0; Zombie=0
total_memory=$( grep -Po '(?<=MemTotal:\s{8})(\d+)' /proc/meminfo )
function MY_Top(){
	for i in `ls /proc | grep '^[0-9]'` ; do
	    if [ -d $i ]; then	
		cd $i
		if [ -f status ]; then 
			utime=$(cat stat | awk '{print $14}')
			stime=$(cat stat | awk '{print $15}')
			cutime=$(cat stat | awk '{print $16}')
			cstime=$(cat stat | awk '{print $17}')
			num_threads=$(cat stat | awk '{print $20}')
			uptime=$( cat /proc/uptime | awk '{print $1 }')
			resident=$(cat statm | awk '{print $2}')
			data_and_stack=$(cat statm | awk '{print $6}')
			starttime=$(cat stat | awk '{print $22}')
			total_time=$(( $utime+$stime ))
			total_time=$(($total_time+$cstime ))
			seconds=$( awk 'BEGIN {print ( '$uptime' - ('$starttime' / '$clock_ticks') )}' )
			pid=$( cat status | awk '{print $2}' | sed -n '6p' )
			ppid=$( cat status | awk '{print $2}' | sed -n '7p' )
			user=$( cat status | awk '{print $2}' | sed -n '9p' | xargs getent passwd | cut -d':' -f1 | colrm 6 )
			group=$( cat status | awk '{print $2}' | sed -n '10p' | xargs getent group | cut -d':' -f1 | colrm 6 )
			pr=$( cat stat | awk  '{print $18}'   )
			ni=$( cat stat | awk '{print $19}' )
			virt=$( cat stat | awk '{ print $23}'| colrm 7 )
			state=$( cat status | awk '{print $2}' | sed -n '3p' )
			cpu=$( awk 'BEGIN {print ( 100 * (('$total_time' / '$clock_ticks') / '$seconds') )}' | colrm 5 )
			mem=$( awk 'BEGIN {print( (('$resident' + '$data_and_stack' ) * 100) / '$total_memory'  ) }' | colrm 5 )
			comm=$( cat status | awk '{print $2}' | sed -n '1p' )
			echo -e "$pid\t$ppid\t$user\t\t$group\t\t$pr\t$ni\t$virt\t$state\t$cpu\t$mem\t$comm" >> ~/TOP/Top.PS 
	    	fi
	fi
	cd ..
done
}
function TOP_OPTION(){
	case $1 in
		k)echo "PID to signal/kill " ; read  Proc_Pid; echo "Send pid  signal " ; read   $signal; kill  $signal $Proc_Pid 2> /dev/null ;;
		q) exit ;;
		r)	
			echo "PID to renice: " ; 
			read  PID_renice ;
			if [ -z "$PID_renice" ] ; then
	    	            echo "Is empty"   
			else
				echo "Renice PID $PID_renice to value"
		                read renice 
		                if [ -z "$renice" ]; then
			                renice=0
					renice -n $renice -p $PID_renice   2> /dev/null	 
			        elif [ "$renice" -lt -20 ] || [ "$renice" -gt 19 ]; then
		                        echo -e "\e[1;47;30m Invaled argument.\e[0m"
			        else
		                        renice -n  $renice -p $PID_renice 2> /dev/null
			        fi
			fi
			;;
		h) for((;;)); do
				clear
				echo -e "\e[1;47;30m Help for Interactive Commands\e[0m"
				echo -e "k,r       Manipulate tasks: 'k' kill; 'r' renice \n q         Quit\nType 'q'  to continue " 
			 done
			;; 
		*) echo -e "\e[1;47;30m Unknown command - try 'h' for help.\e[0m" ;;
	esac
}
for((;;)); do
	clear
	MY_Top &
        echo -e "top -$(uptime [-S hostname] [-hms]) "
        echo -e "KiB Mem : $(free -k | sed -n '2p'| awk '{print $2}' ) total, $(free -k | sed -n '2p'| awk '{print $4}' ) free, $(free -k | sed -n '2p'| awk '{print $3}' ) used, $(free -k | sed -n '2p'| awk '{print $6}' ) buff/cache" 
        echo -e "Kib  Swap : $(free -k | sed -n '3p'| awk '{print $2}' ) total, $(free -k | sed -n '3p'| awk '{print $4}' ) free, $(free -k | sed -n '3p'| awk '{print $3}' ) used, $(free -k | sed -n '2p'| awk '{print $7}' ) avail Mem "
        echo  -e "\e[1;47;30mPID	PPID	USER		GROUP		PR	NI	VIRT	S	%CPU	%MEM	COMMAND					\e[0m" 
	terminal=(`tput lines`)
	lines=$( awk ' BEGIN {print ( '$terminal' - 5)}' )
	sort -k 5 -r  ~/TOP/Top.PS | head -$lines
	read -N 1 -t 0.001 input
	if [ ! -z $input ] ; then 
		TOP_OPTION $input	
	fi
	sleep 3
done

