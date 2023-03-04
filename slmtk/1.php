<?php
session_start();
if (!isset($_SESSION['login']) || $_SESSION['login'] != true) {
    exit("請先登入");
}

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
setStep($workspace, 1);
setProgress($workspace, 50);

// Make DSW call
$output = file_get_contents('http://120.126.151.132:8081/slmtk?usage=1&account=' . $account.'&id='.$id);
$res_json = json_decode($output, true);
if ($res_json['status'] == 'success') {
    echo ("success");
} else {
    echo ("fail: " . $output);
}

// Get data from DSW
$url = "http://120.126.151.132:8081/slmtk/dsw_get_data.php?usage=1&account=$account&id=$id";
$stream = fopen($url, 'rb');
$content = stream_get_contents($stream);
$fn = $_SERVER['DOCUMENT_ROOT'] . '/slmtk/workspace/' . $workspace . '/' . $account . "_1.zip";
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
