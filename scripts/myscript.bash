#! /bin/bash

set -e

if [ $# != 1 ]; then
	echo "Paramatri errati. Inserisci NOME_PROTOCOLLO"
	exit -1
fi

readonly protocol_name=$1

if [ ! -e ../data/${protocol_name}_throughput.dat ]; then
	echo "File non trovato"
	exit -1
fi

# Number of bytes | Median throughput | Overall throughput
declare -a dato_min=($(head -n 1 ../data/${protocol_name}_throughput.dat))
declare -a dato_max=($(tail -n 1 ../data/${protocol_name}_throughput.dat))

dim_min_byte=${dato_min[0]}
dim_max_byte=${dato_max[0]}

throughput_min=$(sed -e 's/[eE][+-]*/\*10\^/' <<< ${dato_min[2]})
throughput_max=$(sed -e 's/[eE][+-]*/\*10\^/' <<< ${dato_max[2]})

delayMin=$(echo $dim_min_byte / $throughput_min | bc)
delayMax=$(echo $dim_max_byte / $throughput_max | bc)

banda=$(echo "scale=9; ($dim_max_byte - $dim_min_byte) / ($delayMax - $delayMin)" | bc)
latenza=$(echo "scale=9; (($delayMin * $dim_max_byte) - ($delayMax * $dim_min_byte)) / ($dim_max_byte - $dim_min_byte)" | bc)

gnuplot <<-eNDgNUPLOTcOMMAND
	set term png size 900, 700
	set output "${protocol_name}PINGPONG.png"
	set logscale x 2
	set logscale y 10
	set xlabel "msg size (B)"
	set ylabel "throughput (KB/s)"
	lbf(x) = x / ( $latenza + x / $banda )
	plot "../data/${protocol_name}_throughput.dat" using 1:3 title "ping-pong ${Protocol} Throughput" with linespoints, \
			lbf(x) title "Latency-Bandwidth model with L=$latenza and B=$banda" with linespoints	     
	clear
eNDgNUPLOTcOMMAND

#573
#455
#96
