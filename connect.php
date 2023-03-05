<?php
/*ini_set("display_errors","On");
error_reporting(E_ALL);*/
$server="127.0.0.1";//主機
$db_username="";//你的資料庫使用者名稱
$db_password="";//你的資料庫密碼
$con = mysqli_connect($server,$db_username,$db_password);//連結資料庫
if($con){
	mysqli_select_db($con, '');//選擇資料庫
	
}else
	exit ("can't connect." . mysqli_error($con));//如果連結失敗輸出錯誤

?>

