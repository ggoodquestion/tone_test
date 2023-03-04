<?php
session_start();
if(!isset($_SESSION['login']) || $_SESSION['login'] != true){
    exit("請先登入");
}

// Initialize workspace folder
include 'connect.php';
$account = trim($_SESSION['account']);
$lf = intval($_POST['lf']);
$hf = intval($_POST['hf']);

$sql = "SELECT * FROM user WHERE account='$account';";
$res = mysqli_query($link, $sql);
if(!$res) exit(mysqli_error($link));
$row = mysqli_fetch_array($res);
$workspace = $row['workspace'];
$id = sprintf('%03d', $row['id']);

// Deal with upload files
$base = $_SERVER['DOCUMENT_ROOT'] . "/slmtk/workspace/";
$upload = $base . $workspace;

// Unzip upload file
$zip = new ZipArchive;
$file = $upload . '/text.zip';
$res = $zip->open($file);

if ($res === true) {
    $zip->extractTo("$upload/text/");
    $zip->close();
}else{
    exit("error1: $res $upload");
}


// Unzip upload file
$zip = new ZipArchive;
$file = $upload . '/wav.zip';
$res = $zip->open($file);
if ($res === true) {
    $zip->extractTo("$upload/wav/");
    $zip->close();
} else {
    exit("error2: $res");
}

unlink($upload.'/text.zip');
unlink($upload.'/wav.zip');

include 'utils.php';
setStep($workspace, 0);
setProgress($workspace, 50);

// Make DSW call
$output = file_get_contents('http://120.126.151.132:8081/slmtk?usage=0&account='.$account.'&id='.$id.'&lf='.$lf.'&hf='.$hf);
$res_json = json_decode($output, true);
if($res_json['status'] == 'success') {
    echo("success");
}else{
    echo("fail: ". $output);
}

setProgress($workspace, 100);

// Generate random dir
function random_dir($length = 8)
{
    $str = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    $dir = substr(str_shuffle($str), 0, $length);
    return $dir;
}

?>