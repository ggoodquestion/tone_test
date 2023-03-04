<?php
/*ini_set("display_errors","On");
error_reporting(E_ALL);*/
$server="localhost";//主機
$db_username="server";//你的資料庫使用者名稱
$db_password="admin512";//你的資料庫密碼
$link = mysqli_connect($server,$db_username,$db_password, 'lab_web', 3306);//連結資料庫
if(!$link){
	exit ("can't connect.");//如果連結失敗輸出錯誤
}
?>

