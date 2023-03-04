<?php
function random_password($length = 8)
{
    $str = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    $password = substr(str_shuffle($str), 0, $length);
    return $password;
}

include './connect.php';
$fp = fopen('./userPair.txt', 'w');
$userPrefix = 'VB';
for($i = 1; $i <= 100; $i++){
    $num = sprintf("%05d", $i);
    $account = $userPrefix . $num;
    $password = random_password();
    $email = $userPrefix . '@test.tw';
    $gender = 2;
    $mother_lang = 0;
    $pwd_hash = password_hash($password, PASSWORD_DEFAULT);
    $sql = "INSERT INTO account_VB(account, password, email, gender, mother_lang, enable) " .
        "VALUES ('$account', '$pwd_hash', '$email', '$gender', '$mother_lang', 1);";
    $result = mysqli_query($con, $sql);
    if (!$result) {
        echo mysqli_error($con);
        $isSucc = false;
        $msg = '註冊失敗';
        exit("註冊失敗");
    }
    fprintf($fp, "%s %s\n", $account, $password);
}
fclose($fp);
echo "Finish";
?>