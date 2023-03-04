<?php
session_start();
if(!isset($_SESSION['login']) || $_SESSION['login'] != true){
    exit("請先登入");
}

// Initialize workspace folder
$base = $_SERVER['DOCUMENT_ROOT'] . "/slmtk/workspace/";
$rid = random_dir();
$rand_dir = $base.$rid;
if(!mkdir($rand_dir, 0777, true)) exit("mkdir fail 1");
if(!mkdir($rand_dir."/text/", 0777, true)) exit("mkdir fail 2");
if(!mkdir($rand_dir."/wav/", 0777, true)) exit("mkdir fail 3");

include 'connect.php';
$username = $_SESSION['account'];


// Deal with upload files
$upload = "$rand_dir/";
$file = $upload . 'text.zip';
$tmp = $_FILES['txtfile']['tmp_name'];
if($_FILES['txtfile']['name'] == '') exit("text file is empty");
if (!move_uploaded_file($tmp, $file)) exit("move $tmp to $file fail");


/*  wav  */
$file = $upload . 'wav.zip';
$tmp = $_FILES['wavfile']['tmp_name'];
if ($_FILES['wavfile']['name'] == '') exit("wav file is empty");
if (!move_uploaded_file($tmp, $file)) exit("move $tmp to $file fail" );

$sql = "UPDATE user SET workspace='$rid' WHERE account='$username';";
$res = mysqli_query($link, $sql);
if(!$res) exit(mysqli_error($link));

$json = array(
    'step'=> -1,
    'progress'=> 0
);
$meta = json_encode($json);
$fp = fopen($rand_dir."/metadata.json", 'w');
fwrite($fp, $meta);
fclose($fp);


echo("success");


// Generate random dir
function random_dir($length = 8)
{
    $str = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    $dir = substr(str_shuffle($str), 0, $length);
    return $dir;
}

?>