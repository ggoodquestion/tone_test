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

include 'utils.php';
setStep($workspace, 8);
setProgress($workspace, 50);

// Make DSW call
$opt = array(
    'http' => array(
        'method' => 'GET',
        'timeout' => 3600
    )
);
$output = file_get_contents('http://120.126.151.132:8081/slmtk?usage=8&account=' . $account.'&id='.$id, false, stream_context_create($opt));
$res_json = json_decode($output, true);
if ($res_json['status'] == 'success') {
    echo ("success");
} else {
    echo ("fail: " . $output);
}

setProgress($workspace, 100);
?>