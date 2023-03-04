<?php
include 'connect.php';
$usage = intval($_GET['usage']);

$account = $_GET['account'];

$sql = "SELECT id, workspace FROM user WHERE account='$account';";
$result = mysqli_query($link, $sql);
$row = mysqli_fetch_array($result);

$id = $row['id'];
$workspace = $row['workspace'];
echo $workspace.'<br/>';
if($usage === 0){
    $path = $_SERVER["DOCUMENT_ROOT"]."/slmtk/workspace/$workspace/";

    $zip = new ZipArchive();
    $fn_zip = $path.$account."_0.zip";
    if (!($zip->open($fn_zip, ZipArchive::CREATE))) {
        exit("cannot open $fn_zip\n");
    }

    // Iterate folder
    // Add .txt
    if ($handle = opendir($path . 'text')) {
        while (false !== ($file = readdir($handle))) {
            if ('.' === $file) continue;
            if ('..' === $file) continue;

            $zip->addFile($path . 'text/' . $file, 'text/' . $file);
            echo $handle;
        }
        closedir($handle);
    }else{
        exit("can't open txt folder");
    }

    // Add .wav
    if ($handle = opendir($path . 'wav')) {
        while (false !== ($file = readdir($handle))) {
            if ('.' === $file) continue;
            if ('..' === $file) continue;

            $zip->addFile($path . 'wav/' . $file, 'wav/' . $file);
        }
        closedir($handle);
    }else{
        exit("can't open wav folder");
    }

    $zip->close();


    if (file_exists($fn_zip)) {
        header('Content-Description: File Transfer');
        header('Content-Type: application/octet-stream');
        header('Content-Disposition: attachment; filename="' . basename($fn_zip) . '"');
        header('Content-Transfer-Encoding: binary');
        header('Content-Length: ' . filesize($fn_zip));
        ob_clean();
        flush();
        readfile($fn_zip);
    }
}
?>