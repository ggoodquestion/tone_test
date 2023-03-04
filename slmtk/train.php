<?php session_start();
$id = $_POST['train_id'];
$server="localhost";//主機
$db_username="revoicetest";//資料庫使用者名稱
$db_password="revoicetest";//資料庫密碼
$con = mysqli_connect($server,$db_username,$db_password);//連結資料庫
mysqli_select_db($con,'testDB');//選擇資料庫
$sql="SELECT  `speakerid`  FROM `user` WHERE  `username` ='".$_SESSION['name']."'";
$result = mysqli_query($con, $sql);
$row=mysqli_fetch_array($result, MYSQLI_BOTH);
$speaker_id=$row['speakerid'];
mysqli_close($con);

//Get user information
//$r_user_data = file_get_contents("https://rvtw.ce.ntpu.edu.tw/VoiceBank/record/api/user_data.php?user=".$_SESSION['name']);
$r_user_data = file_get_contents("https://voicebank.ce.ntpu.edu.tw/record/api/user_data.php?user=".$_SESSION['name']);
$user_data = json_decode($r_user_data, true);
$dir_id = sprintf("%'03d", $user_data['id']);

function getTrainingData($username){
    //$url = "https://rvtw.ce.ntpu.edu.tw/VoiceBank/record/api/training_corpus.php?user=".$username;
    $url = "https://voicebank.ce.ntpu.edu.tw/record/api/training_corpus.php?user=".$username;
    $stream = fopen($url, 'rb');
    $content = stream_get_contents($stream);
    $fp = fopen($username.".zip", "wb");
    fwrite($fp, $content);
    fclose($fp);
    fclose($stream);
}
if($id>=0 &&$id <7){
	if($id == 0 || $id == '0'){
		getTrainingData(trim($_SESSION['name']));
		$cmd = "rm -rf train_data/".$_SESSION['name']."/*.zip";exec($cmd);
		$cmd = "unzip ".$_SESSION['name'].".zip";exec($cmd);
		$cmd = "rm -rf ".$_SESSION['name'].".zip";exec($cmd);
		$cmd = "rm -rf /home/joseph861030/slmtk/egs/tcc300/worksite/".$speaker_id."/in/wav";exec($cmd);
		$cmd = "rm -rf /home/joseph861030/slmtk/egs/tcc300/worksite/".$speaker_id."/in/text";exec($cmd);
		$cmd = "mv ".$dir_id."/wav /home/joseph861030/slmtk/egs/tcc300/worksite/".$speaker_id."/in/wav";exec($cmd);
		$cmd = "mv ".$dir_id."/text /home/joseph861030/slmtk/egs/tcc300/worksite/".$speaker_id."/in/text";exec($cmd);
		$cmd = "rm -rf ".$dir_id;exec($cmd);
		$action = "run-sd-0-clean";
		$dir[0]="/home/joseph861030/slmtk/egs/tcc300/worksite/".$speaker_id."/in -R";
	}
	elseif($id == 1 || $id == '1'){
		$action = "run-sd-1-ta";
		$dir[0]="/home/joseph861030/slmtk/egs/tcc300/worksite/".$speaker_id."/intermediate/ala_sp -R";
	}
	elseif($id == 2 || $id == '2'){
		$action = "run-sd-2-ss";
		$dir[0]="/home/joseph861030/slmtk/egs/tcc300/worksite/".$speaker_id."/intermediate/lab_segrefine -R";
	}
	elseif($id == 3 || $id == '3'){
		$action = "run-sd-3-ilp";
		$dir[0]="/home/joseph861030/slmtk/egs/tcc300/worksite/".$speaker_id."/out/TextGrid -R";
		$dir[1]="/home/joseph861030/slmtk/egs/tcc300/worksite/".$speaker_id."/intermediate/ff0 -R";
		$dir[2]="/home/joseph861030/slmtk/egs/tcc300/worksite/".$speaker_id."/intermediate/al/all.al";
	}
	elseif($id == 4 || $id == '4'){
		$action = "run-sd-4-plm";
		$dir[0]="/home/joseph861030/slmtk/egs/tcc300/worksite/".$speaker_id."/intermediate/transxpb -R";
	}
	elseif($id == 5 || $id == '5'){
		$action = "run-sd-5-cpg";
		$dir[0]="/home/joseph861030/slmtk/egs/tcc300/worksite/".$speaker_id."/out/source/pg_rvtw -R";
	}
	elseif($id == 6 ){
		$action = "run-sd-6-hts";
		$dir[0]="/home/joseph861030/slmtk/egs/tcc300/worksite/".$speaker_id."/out/source/ss -R";
	}

	$cmd = "sh ./train.sh ".$action." ".$speaker_id;exec($cmd);
	
	if(isset($dir)){
		$cmd = "mkdir ".$id;exec($cmd);
		for($i=0;$i<count($dir);$i++){
			$cmd="cp ".$dir[$i]." ".$id;exec($cmd);
		}
		$cmd = "zip -r train_data/".$_SESSION['name']."/".$id.".zip ".$id;exec($cmd);
		$cmd = "rm -rf ".$id;exec($cmd);
	}
}
elseif($id == 7 || $id == '7'){
	$cmd = "sh ./release.sh ".$speaker_id;exec($cmd);
}
elseif($id == 8 || $id == '8'){
	getTrainingData(trim($_SESSION['name']));
	$cmd = "rm -rf train_data/".$_SESSION['name']."/*.zip";exec($cmd);
	$cmd = "unzip ".$_SESSION['name'].".zip";exec($cmd);
	$cmd = "rm -rf ".$_SESSION['name'].".zip";exec($cmd);
	$cmd = "rm -rf /home/joseph861030/slmtk/egs/tcc300/worksite/".$speaker_id."/in/wav";exec($cmd);
	$cmd = "rm -rf /home/joseph861030/slmtk/egs/tcc300/worksite/".$speaker_id."/in/text";exec($cmd);
	$cmd = "mv ".$dir_id."/wav /home/joseph861030/slmtk/egs/tcc300/worksite/".$speaker_id."/in/wav";exec($cmd);
	$cmd = "mv ".$dir_id."/text /home/joseph861030/slmtk/egs/tcc300/worksite/".$speaker_id."/in/text";exec($cmd);
	$cmd = "rm -rf ".$dir_id;exec($cmd);
	$action = "run-sd-all";
	$cmd = "sh ./train.sh ".$action." ".$speaker_id;exec($cmd);
}

?>