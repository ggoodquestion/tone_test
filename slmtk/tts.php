<?php
session_start();
if (!isset($_SESSION['login']) || $_SESSION['login'] != true) {
    exit("請先登入");
}
set_time_limit(0); // Set to not limit exec time

// Initialize workspace folder
include 'connect.php';
$account = trim($_SESSION['account']);

$sql = "SELECT * FROM user WHERE account='$account';";
$res = mysqli_query($link, $sql);
if (!$res) exit(mysqli_error($link));
$row = mysqli_fetch_array($res);
$workspace = $row['workspace'];
$id = sprintf('%03d', $row['id']);


// Make DSW call
$data = array(
    "account"=> $account,
    "id"=> $id,
    "usage"=> 9,
    "input"=> $_POST['input'],
    "type"=> $_POST['type']
);
$opt = array(
    'http' => array(
        'header'  => "Content-type: application/x-www-form-urlencoded\r\n",
        'method' => 'POST',
        'content' => http_build_query($data),
        'timeout' => 3600
    )
);

$cmd = "mkdir " . $_SERVER['DOCUMENT_ROOT'] . '/slmtk/workspace/' . $workspace . '/convert/'; exec($cmd);

$output = file_get_contents('http://120.126.151.132:8081/slmtk/dsw_tts.php', false, stream_context_create($opt));

$date = date('Y-m-d-h-i-s', time());
$fn = $_SERVER['DOCUMENT_ROOT'] . '/slmtk/workspace/' . $workspace . '/convert/' . $account."_".$date.".wav";
$fp = fopen($fn, "wb");
fwrite($fp, $output);
fclose($fp);

// Get data from DSW
// $url = 'http://120.126.151.132:8081/slmtk/dsw_tts.php';
// $stream = fopen($url, 'rb', false, stream_context_create($opt));
// $content = stream_get_contents($stream);
// exit($content);
// $fn = $_SERVER['DOCUMENT_ROOT'] . '/slmtk/workspace/' . $workspace . '/convert/' . $account . "_" . $date . ".wav";
// if (!$fp = fopen($fn, "wb")) exit("fail to open file");
// fwrite($fp, $content);
// fclose($fp);
// fclose($stream);

echo  $account."_".$date.".wav";

?>