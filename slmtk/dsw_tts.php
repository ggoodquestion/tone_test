<?php
$id = $_POST['id'];
$account = $_POST['account'];
$input = $_POST['input'];
$type = $_POST['type'];

$root = "/var/www/html/slmtk/usr/$account/convert/"; 

$cmd = "mkdir $root";exec($cmd);

$date = date('Y-m-d-h-i-s', time());

$fn = $id . '_' . $date . '.txt';
$fp = fopen($root.$fn, 'w');
fprintf($fp, "%s\n", $input);
fclose($fp);

$basedir = "/home/jiajusu/slmtk/egs/SLMTK1.0/release/ntpu-tts-SLMTK1.0/";
$prefix = $id."_slmtk";
$full_fn = $root.$fn;
$output_dir = $root;
$sr = "0.20";

$cmd = "sh $basedir/bin/run_rv.sh $basedir $id $prefix $full_fn $output_dir $sr $type"; exec($cmd);

$output_fn = "$prefix-sr_$sr-$type.wav";

if (file_exists($root.$output_fn)) {
    header('Content-Description: File Transfer');
    header('Content-Type: application/octet-stream');
    header('Content-Disposition: attachment; filename="' . basename($root.$output_fn) . '"');
    header('Content-Transfer-Encoding: binary');
    header('Content-Length: ' . filesize($root.$output_fn));
    ob_clean();
    flush();
    readfile($root.$output_fn);
}else{
    echo "Fail to download $root$output_fn";
}

// echo setResponse("$root", "tts");

// function setResponse($status, $msg)
// {
//     $res = array(
//         "status" => $status,
//         "msg"   => $msg
//     );
//     $res = json_encode($res);
//     return $res;
// }
?>