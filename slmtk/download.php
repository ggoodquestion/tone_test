<?php
session_start();
include "./connect.php";

$usage = intval($_GET['usage']);
$account = $_SESSION['account'];

$sql = "SELECT id, workspace FROM user WHERE account='$account';";
$result = mysqli_query($link, $sql);
$row = mysqli_fetch_array($result);

$id = $row['id'];
$workspace = $row['workspace'];


// Define zip
$path = $_SERVER["DOCUMENT_ROOT"] . "/slmtk/workspace/$workspace/";

$zip = new ZipArchive();


if ($usage == 0) { // For corpus
    $fn_zip = $path . "corpus_$account.zip";
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
    } else {
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
    } else {
        exit("can't open wav folder");
    }

    $zip->close();
}else if($usage == 1){ //For .ala
    $fn_zip = $path . "ta_$account.zip";
    if (!($zip->open($fn_zip, ZipArchive::CREATE))) {
        exit("cannot open $fn_zip\n");
    }
    // Iterate folder
    // Add .ala
    if ($handle = opendir($path . 'llf')) {
        while (false !== ($file = readdir($handle))) {
            if ('.' === $file) continue;
            if ('..' === $file) continue;

            $zip->addFile($path . 'llf/' . $file, 'llf/' . $file);
        }
        closedir($handle);
    } else {
        exit("can't open txt folder");
    }
}else if($usage == 2){ //For .ala
    $fn_zip = $path . "afe_$account.zip";
    if (!($zip->open($fn_zip, ZipArchive::CREATE))) {
        exit("cannot open $fn_zip\n");
    }
    // Iterate folder
    // Add .wav16k
    if ($handle = opendir($path . 'wav16k')) {
        while (false !== ($file = readdir($handle))) {
            if ('.' === $file) continue;
            if ('..' === $file) continue;

            $zip->addFile($path . 'wav16k/' . $file, 'wav16k/' . $file);
        }
        closedir($handle);
    } else {
        exit("can't open txt folder");
    }

    // Add .wav20k
    if ($handle = opendir($path . 'wav20k')) {
        while (false !== ($file = readdir($handle))) {
            if ('.' === $file) continue;
            if ('..' === $file) continue;

            $zip->addFile($path . 'wav20k/' . $file, 'wav20k/' . $file);
        }
        closedir($handle);
    } else {
        exit("can't open txt folder");
    }

    // Add .f0
    if ($handle = opendir($path . 'f0')) {
        while (false !== ($file = readdir($handle))) {
            if ('.' === $file) continue;
            if ('..' === $file) continue;

            $zip->addFile($path . 'f0/' . $file, 'f0/' . $file);
        }
        closedir($handle);
    } else {
        exit("can't open txt folder");
    }
}else if($usage == 3){ //For .ala
    $fn_zip = $path . "lsa_$account.zip";
    if (!($zip->open($fn_zip, ZipArchive::CREATE))) {
        exit("cannot open $fn_zip\n");
    }
    // Iterate folder
    // Add .TextGrid
    if ($handle = opendir($path . "TextGrid")) {
        while (false !== ($file = readdir($handle))) {
            if ('.' === $file) continue;
            if ('..' === $file) continue;

            $zip->addFile($path . "TextGrid/" . $file, 'TextGrid/' . $file);
            echo $handle . '<br/>';
        }
        closedir($handle);
    } else {
        exit("can't open TextGrid folder");
    }

} else if ($usage == 4) {
    $fn_zip = $path . "ilp_$account.zip";
    if (!($zip->open($fn_zip, ZipArchive::CREATE))) {
        exit("cannot open $fn_zip\n");
    }
    $zip->addFile($path . "subsets_stats.txt", "subsets_stats.txt");
    $zip->addFile($path . "all.ori.slp", "all.ori.slp");

    // Iterate folder
    // Add .TextGrid
    if ($handle = opendir($path . "TextGrid_ilp")) {
        while (false !== ($file = readdir($handle))) {
            if ('.' === $file) continue;
            if ('..' === $file) continue;

            $zip->addFile($path . "TextGrid_ilp/" . $file, 'TextGrid_ilp/' . $file);
            echo $handle . '<br/>';
        }
        closedir($handle);
    } else {
        exit("can't open transxpb folder");
    }

} else if($usage == 5){ //For .ala
    $fn_zip = $path . "plm_$account.zip";
    if (!($zip->open($fn_zip, ZipArchive::CREATE))) {
        exit("cannot open $fn_zip\n");
    }
    // Iterate folder
    // Add .TextGrid
    if ($handle = opendir($path . "transxpb")) {
        while (false !== ($file = readdir($handle))) {
            if ('.' === $file) continue;
            if ('..' === $file) continue;

            $zip->addFile($path . "transxpb/" . $file, 'transxpb/' . $file);
            echo $handle . '<br/>';
        }
        closedir($handle);
    } else {
        exit("can't open transxpb folder");
    }

    // Add .TextGrid
    if ($handle = opendir($path . "TextGrid_plm")
    ) {
        while (false !== ($file = readdir($handle))) {
            if ('.' === $file) continue;
            if ('..' === $file) continue;

            $zip->addFile($path . "TextGrid_plm/" . $file, 'TextGrid_plm/' . $file);
            echo $handle . '<br/>';
        }
        closedir($handle);
    } else {
        exit("can't open TextGrid_plm folder");
    }

} else if ($usage == 7) { //For .ala
    $fn_zip = $path . "hts_$account.zip";
    if (!($zip->open($fn_zip, ZipArchive::CREATE))) {
        exit("cannot open $fn_zip\n");
    }
    // Iterate folder
    // Add .TextGrid
    if ($handle = opendir($path . "test")) {
        while (false !== ($file = readdir($handle))) {
            if ('.' === $file) continue;
            if ('..' === $file) continue;

            $zip->addFile($path . "test/" . $file, 'test/' . $file);
            echo $handle . '<br/>';
        }
        closedir($handle);
    } else {
        exit("can't open test folder");
    }

    $zip->addFile($path . "file_mapping.txt", "file_mapping.txt");
}

// echo "請重新整理";
$zip->close();
// Download process
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
unlink($fn_zip);
?>