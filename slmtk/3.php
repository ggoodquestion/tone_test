<?php
session_start();
if (!isset($_SESSION['login']) || $_SESSION['login'] != true) {
    exit("請先登入");
}
ini_set('default_socket_timeout', 900); // 900 Seconds = 15 Minutes

// Initialize workspace folder
include 'connect.php';
$account = trim($_SESSION['account']);

$sql = "SELECT * FROM user WHERE account='$account';";
$res = mysqli_query($link, $sql);
if (!$res) exit(mysqli_error($link));
$row = mysqli_fetch_array($res);
$workspace = $row['workspace'];
$id = sprintf('%03d', $row['id']);

include 'utils.php';
setStep($workspace, 3);
setProgress($workspace, 50);

// Make DSW call
$opt = array(
    'http' => array(
        'method' => 'GET',
        'timeout' => 900
    )
);
$output = file_get_contents('http://120.126.151.132:8081/slmtk?usage=3&account=' . $account.'&id='.$id, false, stream_context_create($opt));
$res_json = json_decode($output, true);
if ($res_json['status'] == 'success') {
    echo ("success");
} else {
    echo ("fail: " . $output);
}

// Get data from DSW
$url = "http://120.126.151.132:8081/slmtk/dsw_get_data.php?usage=3&account=$account&id=$id";
$stream = fopen($url, 'rb');
$content = stream_get_contents($stream);
$fn = $_SERVER['DOCUMENT_ROOT'] . '/slmtk/workspace/' . $workspace . '/' . $account . "_3.zip";
if (!$fp = fopen($fn, "wb")) exit("fail to open file");
fwrite($fp, $content);
fclose($fp);
fclose($stream);

// Unzip
$zip = new ZipArchive;
$res = $zip->open($fn);

if ($res === true) {
    $zip->extractTo($_SERVER['DOCUMENT_ROOT'] . '/slmtk/workspace/' . $workspace);
    $zip->close();
} else {
    exit("fail");
}

setProgress($workspace, 100);
?>
