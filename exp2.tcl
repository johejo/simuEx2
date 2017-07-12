set ns [new Simulator]

#set nf [open out.nam w]
#$ns namtrace-all $nf

#set tf [open out.tr w]
set NumbSrc [expr [lindex $argv 0] / 2]
set NumbDst [lindex $argv 0]
#set windowVsTime [open win w]
#set param [open parameters w]
#$ns trace-all $tf



#Define a 'finish' procedure
proc finish {} {
    global ns avg_th tcp_snk NumbSrc Duration
    #global nf tf

	$ns flush-trace
	#close $nf; close $tf
	#exec nam out.nam &

    for {set j 1} {$j<=$NumbDst} { incr j } {
        set th [expr double([$tcp_snk($j) set bytes_]*8.0/$Duration)]  ;;#ここで、平均スループットを計算。600のところはシミュレーション時間を指定
        puts "[format "%.2f" $th]" ;;#  端末に出力
        #puts $avg_th "[format "%.2lf" $th]"  ;;#  ファイルに出力*/
    }


	exit 0
}

#Create bottleneck and dest nodes
set n2 [$ns node]
set n3 [$ns node]



#Create links between these nodes
$ns duplex-link $n2 $n3 10Mb 10ms DropTail

#Set error model on link n2 to n3.
set loss_module [new ErrorModel]
set err_rate 0.0001
$loss_module set rate_ $err_rate
$loss_module unit pkt
$loss_module ranvar [new RandomVariable/Uniform]
$loss_module drop-target [new Agent/Null]
$ns lossmodel $loss_module $n2 $n3


set Duration 60

#Source nodes
for {set j 1} {$j<=$NumbSrc} { incr j } {
	set S_A($j) [$ns node]
    set S_B($j) [$ns node]
}

#Destination node
for {set j 1} {$j<=$NumbDst} { incr j } {
	set D($j) [$ns node]
}

# Create a random generator for starting the ftp and for bottleneck link delays
set rng [new RNG]
$rng seed 0


# parameters for random variables for begenning of ftp connections
set RVstart [new RandomVariable/Uniform]
$RVstart set min_ 0
$RVstart set max_ 0.1
$RVstart use-rng $rng

#We define two random parameters for each connections
for {set i 1} {$i<=$NumbSrc} { incr i } {
	set startT($i)  [expr [$RVstart value]]
	#puts $param "startT($i)  $startT($i) sec"
}

#Links between source and bottleneck
for {set j 1} {$j<=$NumbSrc} { incr j } {
	$ns duplex-link $S($j) $n2 100Mb 10ms DropTail
	$ns queue-limit $S($j) $n2 37.5
}

#Links between distinations and bottleneck
for {set j 1} {$j<=$NumbSrc} { incr j } {
	$ns duplex-link $D($j) $n2 100Mb 10ms DropTail
	$ns queue-limit $D($j) $n2 37.5
}

#Monitor the queue for link (n2-n3). (for NAM)
#$ns duplex-link-op $n2 $n3 queuePos 0.5

#Set Queue Size of link (n2-n3) to 10
$ns queue-limit $n2 $n3 37.5

#TCP Sources
for {set j 1} {$j<=$NumbSrc} { incr j } {
	set tcp_src($j) [new Agent/TCP/Sack1]
    $tcp_src($j) set fid_ $j
}

#TCP Destinations
for {set j 1} {$j<=$NumbSrc} { incr j } {
	set tcp_snk($j) [new Agent/TCPSink/Sack1]
    $tcp_snk($j) set window_ 37.5
}

#Connections
for {set j 1} {$j<=$NumbSrc} { incr j } {
	$ns attach-agent $S($j) $tcp_src($j)
	$ns attach-agent $D($j) $tcp_snk($j)
	$ns connect $tcp_src($j) $tcp_snk($j)
}

#FTP sources
for {set j 1} {$j<=$NumbSrc} { incr j } {
	set ftp($j) [$tcp_src($j) attach-source FTP]
}

#Parametrisation of TCP sources
for {set j 1} {$j<=$NumbSrc} { incr j } {
	$tcp_src($j) set packetSize_ 1000
}

#Schedule events for the FTP agents:
for {set i 1} {$i<=$NumbSrc} { incr i } {
	$ns at $startT($i) "$ftp($i) start"
	$ns at $Duration "$ftp($i) stop"
}

#set th_time [open th.tr w] ;;# スループットの時間変化をth.trというファイルに出力させる場合
proc plotth {tcpSource file n_byte p_byte} {
    global ns
    set time 1.0 ;;# スループットの出力間隔(この例では1秒ごと)
    set now [$ns now]
    set n_byte [expr [$tcpSource set bytes_]-$p_byte]
    set th [expr double($n_byte*8.0/$time)]
    set p_byte [$tcpSource set bytes_]
    #puts $file "$now $th";;# ここで測定間隔ごとのスループットがファイルに出力される
    #$ns at [expr $now+$time] "plotth $tcpSource $file $n_byte $p_byte"
}
set n_byte 0
set p_byte 0


#  平均値はfinish関数で計算可能 (result.txtというファイルに出力する場合)
#set avg_th [open ./result.txt a]

proc plotWindow {tcpSource file k} {
	global ns
	set time 0.03
	set now [$ns now]
	set cwnd [$tcpSource set cwnd_]
	puts $file "$k $now $cwnd"
	$ns at [expr $now+$time] "plotWindow $tcpSource $file $k"
}

# The procedure will now be called for all tcp sources
#for {set j 1} {$j<=$NumbSrc} { incr j } {
	#$ns at 0.1 "plotWindow $tcp_src($j) $windowVsTime $j"
    #$ns at 0.1 "plotth $tcp_snk($j) $th_time $n_byte $p_byte"
#}

$ns at [expr $Duration] "finish"
$ns run
