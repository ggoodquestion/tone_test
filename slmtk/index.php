<?php
$usage = intval($_GET['usage']);
$account = $_GET['account'];
$id = $_GET['id'];

if($usage === 0){
    // Get data
    getData($usage, $account);

    $lf = intval($_GET['lf']);
    $hf = intval($_GET['hf']);

    // Create new user folder
    $slmtk_root = "/home/jiajusu/slmtk/egs/SLMTK1.0/worksite/";
    if(!file_exists("$slmtk_root$id")){
        $action = "worksite-sd";
        $cmd = "sh ./train.sh ".$action." ".$id;exec($cmd);
    }else{
        // Delete all in intermediate
        $cmd = "rm -r $slmtk_root$id/intermediate/*"; exec($cmd);
        $cmd = "rm $slmtk_root$id/config.speaker.$id.json";exec($cmd);
    }
    // Clear transfer area
    $cmd = "rm -r /var/www/html/slmtk/usr/$account"; exec($cmd);

    // Add speaker config
    $speaker_config = array(
        "encoding"=> "UTF-8",
        "speakers"=>  array(
            array(
                "name"=> "$id",
                "databasedir"=> "/home/jiajusu/slmtk/egs/SLMTK1.0/worksite/$id",
                "LOWERF0HZ"=> $lf,
                "UPPERF0HZ"=> $hf,
                "PURE_ENG_UTT_STR"=> "NULL",
                "running_mode"=> "full"
            )
        )
    );
    $json = json_encode($speaker_config);
    $cmd = "echo '$json' > $slmtk_root$id/config.speaker.$id.json";exec($cmd);
    
    // Copy zip file and unzip
    $fn_zip = $_SERVER['DOCUMENT_ROOT']."/slmtk/doc/".$account."_0.zip";
    $target_path = "$slmtk_root$id";
    // $cmd = "cp $zip $target_path";exec($cmd);
    // copy($zip, $target_path);

    // Clean corpus
    $cmd = "rm -r $slmtk_root$id/in/*";exec($cmd);

    $zip = new ZipArchive;
    $res = $zip->open($fn_zip);

    if ($res === true) {
        $zip->extractTo("$target_path/in");
        $zip->close();
    }else{
        exit(setResponse("Fail", "unzip fail"));
    }

    // checkAndAddNewUser($id, $lf, $hf);

    //make scrpit file
    $action = "script-sd";
    $cmd = "sh ./train.sh ".$action." ".$id;exec($cmd);

    // Run run-sd-0-clean
    $action = "run-sd-0-clean";
    $cmd = "sh ./train.sh ".$action." ".$id;exec($cmd);
    $cmd = "chmod -R 777 $slmtk_root$id";exec($cmd);

    echo setResponse("success", "initialize");
}else if($usage == 1){
    // Run run-sd-1-ta
    $action = "run-sd-1-ta";
    $cmd = "sh ./train.sh ".$action." ".$id;exec($cmd);

    echo setResponse("success", "ta");
}else if($usage == 2){
    // Run run-sd-2-afe
    $action = "run-sd-2-afe";
    $cmd = "sh ./train.sh ".$action." ".$id;exec($cmd);

    echo setResponse("success", "afe");
}else if($usage == 3){
    // Run run-sd-3-lsa
    $action = "run-sd-3-lsa";
    $cmd = "sh ./train.sh ".$action." ".$id;exec($cmd);

    echo setResponse("success", "lsa");
} else if ($usage == 4) {
    // Run run-sd-4-ilp
    $action = "run-sd-4-ilp";
    $cmd = "sh ./train.sh " . $action . " " . $id;
    exec($cmd);

    echo setResponse("success", "ilp");
} else if ($usage == 5) {
    // Run run-sd-5-plm
    $action = "run-sd-5-plm";
    $cmd = "sh ./train.sh " . $action . " " . $id;
    exec($cmd);

    echo setResponse("success", "plm");
} else if ($usage == 6) {
    // Run run-sd-6-cpg
    $action = "run-sd-6-cpg";
    $cmd = "sh ./train.sh " . $action . " " . $id;
    exec($cmd);

    echo setResponse("success", "cpg");
} else if ($usage == 7) {
    // Run run-sd-7-hts
    $action = "run-sd-7-hts";
    $cmd = "sh ./train.sh " . $action . " " . $id;
    exec($cmd);

    echo setResponse("success", "cpg");
} else if ($usage == 8) {
    // Run release 
    $cmd ="sh ./release.sh " . $id;
    if(!exec($cmd)) exit(setResponse("fail", "deploy release"));

    echo setResponse("success", "release");
}

function getData($usage, $account){
    // Get data
    $url = "http://120.126.152.230/slmtk/get_data.php?usage=$usage&account=$account";
    $stream = fopen($url, 'rb');
    $content = stream_get_contents($stream);
    $fn = $_SERVER['DOCUMENT_ROOT'].'/slmtk/doc/'.$account."_".$usage.".zip";
    if(!$fp = fopen($fn, "wb")) exit("fail to open file");
    fwrite($fp, $content);
    fclose($fp);
    fclose($stream);
}

function setResponse($status, $msg){
    $res = array(
        "status"=> $status,
        "msg"   => $msg
    );
    $res = json_encode($res);
    return $res;
}

function checkAndAddNewUser($id, $lf, $hf){
    $speakers_json = "/home/jiajusu/slmtk/egs/SLMTK1.0/config/config.speaker.json";
    $config = file_get_contents($speakers_json);
    $config = json_decode($config, true);
    $speakers = $config['speakers'];

    $flag = false;
    foreach($speakers as $speaker){
        if($speaker['name'] == $id){
            $flag = true;
            return;
        }
    }

    if(!$flag){
        // If is a new user then add in to config
        $new = array(
            'name'=> $id,
            'databasedir'=> "/home/jiajusu/slmtk/egs/SLMTK1.0/worksite/$id",
            'LOWERF0HZ'=> $lf,
            'UPPERF0HZ'=> $hf,
            'PURE_ENG_UTT_STR'=> "NULL",
            'running_mode'=> "full"
        );
        $config['speakers'][] = $new;
        $config = json_encode($config);
        $cmd = "echo '$config' > $speakers_json";exec($cmd);

        // Initialize by run make
        $cmd = "sh ./train.sh config";exec($cmd);
    }
}
?>