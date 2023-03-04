<?php
function setStep($id, $step){
    $path = $_SERVER['DOCUMENT_ROOT']."/slmtk/workspace/$id/metadata.json";
    $data = file_get_contents($path);
    $json = json_decode($data, true);
    $json['step'] = $step;
    $json = json_encode($json);
    file_put_contents($path, $json);
}

function setProgress($id, $progress){
    $path = $_SERVER['DOCUMENT_ROOT']."/slmtk/workspace/$id/metadata.json";
    $json = json_decode(file_get_contents($path), true);
    $json['progress'] = $progress;
    $json = json_encode($json);
    file_put_contents($path, $json);
}
?>