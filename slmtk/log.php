<?php
session_start();
$id = sprintf("%03d", intval($_GET['id']));
$usage = $_GET['usage'];

switch ($usage) {
    case '0':
        $process = "clean";
        break;
    case '1':
        $process = "ta";
        break;
    case '2':
        $process = "afe";
        break;
    case '3':
        $process = "lsa";
        break;
    case '4':
        $process = "ilp";
        break;
    case '5':
        $process = "plm";
        break;
    case '6':
        $process = "cpg";
        break;
    case '7':
        $process = "hts";
        break;
}

$log_fn = "/home/jiajusu/slmtk/egs/SLMTK1.0/worksite/$id/$id.$usage.$process.log";
$cmd = "cat $log_fn";
$log = shell_exec($cmd);
$log = explode("\n", $log);

$start_regx = "*\[start\] \(\d+\/\d+\) [\S\D]+*";
$end_regx = "*\[end\] \(\d+\/\d+\) [\S\D]+*";

$tmp = array();

foreach ($log as $l){
    if(preg_match($start_regx, $l, $out)){
        $tmp[] = $out[0];
    }if(preg_match($end_regx, $l, $out)){
        $tmp[] = $out[0];
    }
}

$res = "";
foreach($tmp as $s){
    $res .= "$s</br>";
}

echo $res;
?>