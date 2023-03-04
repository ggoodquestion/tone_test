<?php
$id = $_GET['id'];
$usage = $_GET['usage'];
$res = file_get_contents("http://120.126.151.132:8081/slmtk/log.php?usage=$usage&id=$id");
echo $res;
?>