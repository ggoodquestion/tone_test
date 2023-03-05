<?php
include 'connect.php';
$sn   = $_POST['sn'];
$user = $_POST['user'];
$id   = $_POST['id'];
$wav  = $_POST['wav'];
$txt  = $_POST['txt'];
$qes  = $_POST['qes'];
$ans  = $_POST['ans'];

if($ans == ''){
    $msg = array(
        'state' => 'fail',
        'msg' =>  'Please select a option'
    );
    $json = json_encode($msg);
    exit($json);
}

$sql = "SELECT * FROM question WHERE sn = $sn AND user_id = $id;";
$res = mysqli_query($con, $sql);
if($res->num_rows == 0){
    // No record, then insert
    $sql = "INSERT INTO question(wav, content, qes, ans, user_id, sn) VALUES ('$wav', '$txt', '$qes', $ans, $id, $sn)";
    $res = mysqli_query($con, $sql);
    if(!$res){
        $msg = array(
            'state' => 'error',
            'msg' =>  mysqli_error($con).$sql
        );
        $json = json_encode($msg);
        exit($json);
    }else{
        $msg = array(
            'state' => 'success',
            'msg' =>  'submit successful'
        );
        $json = json_encode($msg);
        exit($json);
    }   
}else{
    // Already have a record, then update
    $sql = "UPDATE question SET ans = $ans WHERE user_id = $id AND sn = $sn;";
    $res = mysqli_query($con, $sql);
    if (!$res) {
        $msg = array(
            'state' => 'error',
            'msg' =>  mysqli_error($con)
        );
        $json = json_encode($msg);
        exit($json);
    } else {
        $msg = array(
                'state' => 'success',
                'msg' =>  'update successful'
            );
        $json = json_encode($msg);
        exit($json);
    }
}
?>