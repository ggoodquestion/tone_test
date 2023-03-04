<?php
include 'connect.php';
$usage = intval($_GET['usage']);

$account = $_GET['account'];
$id = $_GET['id'];

// Clean tmp dir
// $cmd = "rm -r ".$_SERVER['DOCUMENT_ROOT']."/slmtk/usr/$account/"; exec($cmd);
$slmtk_root = "/home/jiajusu/slmtk/egs/SLMTK1.0/worksite/";

if($usage === 1){
    // Build user dir and copy file
    $cmd = "mkdir ".$_SERVER['DOCUMENT_ROOT']."/slmtk/usr/$account";exec($cmd);
    $cmd = "rm -r ".$_SERVER['DOCUMENT_ROOT']."/slmtk/usr/$account/llf/*";exec($cmd);
    $cmd = "cp -R $slmtk_root$id/out/llf/ ".$_SERVER['DOCUMENT_ROOT']."/slmtk/usr/$account/";exec($cmd);

    $zip = new ZipArchive();
    $path = $_SERVER['DOCUMENT_ROOT']."/slmtk/usr/$account/";
    $fn_zip = $path.$account."_1.zip";
    if (!($zip->open($fn_zip, ZipArchive::CREATE))) {
        exit("cannot open $fn_zip\n");
    }
    // Iterate folder
    // Add .ala
    if ($handle = opendir($path."llf")) {
        while (false !== ($file = readdir($handle))) {
            if ('.' === $file) continue;
            if ('..' === $file) continue;

            $zip->addFile($path . "llf/" .$file, 'llf/' . $file);
            echo $handle .'<br/>';
        }
        closedir($handle);
    }else{
        exit("can't open txt folder");
    }

    
}else if($usage == 2){
    // Build user dir and copy file
    $cmd = "mkdir ".$_SERVER['DOCUMENT_ROOT']."/slmtk/usr/$account";exec($cmd);
    $cmd = "rm -r ".$_SERVER['DOCUMENT_ROOT']."/slmtk/usr/$account/wav16k/*";exec($cmd);
    $cmd = "rm -r ".$_SERVER['DOCUMENT_ROOT']."/slmtk/usr/$account/wav20k/*";exec($cmd);
    $cmd = "rm -r ".$_SERVER['DOCUMENT_ROOT']."/slmtk/usr/$account/f0/*";exec($cmd);
    $cmd = "cp -R $slmtk_root$id/intermediate/wav16k/ ".$_SERVER['DOCUMENT_ROOT']."/slmtk/usr/$account/";exec($cmd);
    $cmd = "cp -R $slmtk_root$id/intermediate/wav20k/ ".$_SERVER['DOCUMENT_ROOT']."/slmtk/usr/$account/";exec($cmd);
    $cmd = "cp -R $slmtk_root$id/intermediate/f0/ ".$_SERVER['DOCUMENT_ROOT']."/slmtk/usr/$account/";exec($cmd);

    $zip = new ZipArchive();
    $path = $_SERVER['DOCUMENT_ROOT']."/slmtk/usr/$account/";
    $fn_zip = $path.$account."_2.zip";
    if (!($zip->open($fn_zip, ZipArchive::CREATE))) {
        exit("cannot open $fn_zip\n");
    }
    // Iterate folder
    // Add .wav16
    if ($handle = opendir($path."wav16k")) {
        while (false !== ($file = readdir($handle))) {
            if ('.' === $file) continue;
            if ('..' === $file) continue;

            $zip->addFile($path . "wav16k/" .$file, 'wav16k/' . $file);
            echo $handle .'<br/>';
        }
        closedir($handle);
    }else{
        exit("can't open txt folder");
    }

    // Add .wav20
    if ($handle = opendir($path."wav20k")) {
        while (false !== ($file = readdir($handle))) {
            if ('.' === $file) continue;
            if ('..' === $file) continue;

            $zip->addFile($path . "wav20k/" .$file, 'wav20k/' . $file);
            echo $handle .'<br/>';
        }
        closedir($handle);
    }else{
        exit("can't open txt folder");
    }

    // Add .f0
    if ($handle = opendir($path."f0")) {
        while (false !== ($file = readdir($handle))) {
            if ('.' === $file) continue;
            if ('..' === $file) continue;

            $zip->addFile($path . "f0/" .$file, 'f0/' . $file);
            echo $handle .'<br/>';
        }
        closedir($handle);
    }else{
        exit("can't open txt folder");
    }
} else if ($usage == 3) {
    // Build user dir and copy file
    $cmd = "mkdir " . $_SERVER['DOCUMENT_ROOT'] . "/slmtk/usr/$account";
    exec($cmd);

    // Copy output data "Textgrid, ff0, al"
    $cmd = "rm -r ".$_SERVER['DOCUMENT_ROOT']."/slmtk/usr/$account/TextGrid/*";exec($cmd);
    $cmd = "cp -R $slmtk_root$id/out/TextGrid/ " . $_SERVER['DOCUMENT_ROOT'] . "/slmtk/usr/$account/"; exec($cmd); // TextGrid

    $zip = new ZipArchive();
    $path = $_SERVER['DOCUMENT_ROOT'] . "/slmtk/usr/$account/";
    $fn_zip = $path . $account . "_3.zip";
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
    // Build user dir and copy file
    $cmd = "mkdir " . $_SERVER['DOCUMENT_ROOT'] . "/slmtk/usr/$account";
    exec($cmd);
    $cmd = "cp $slmtk_root$id/intermediate/subsets_stats.txt " . $_SERVER['DOCUMENT_ROOT'] . "/slmtk/usr/$account/";
    exec($cmd);
    $cmd = "cp $slmtk_root$id/out/all.ori.slp " . $_SERVER['DOCUMENT_ROOT'] . "/slmtk/usr/$account/";
    exec($cmd);
    $cmd = "rm -r " . $_SERVER['DOCUMENT_ROOT'] . "/slmtk/usr/$account/TextGrid_ilp/*";
    exec($cmd);
    $cmd = "cp -R $slmtk_root$id/out/TextGrid_ilp/ " . $_SERVER['DOCUMENT_ROOT'] . "/slmtk/usr/$account/";
    exec($cmd);

    $zip = new ZipArchive();
    $path = $_SERVER['DOCUMENT_ROOT'] . "/slmtk/usr/$account/";
    $fn_zip = $path . $account . "_4.zip";
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
    
} else if ($usage == 5) {
    // Build user dir and copy file
    $cmd = "mkdir " . $_SERVER['DOCUMENT_ROOT'] . "/slmtk/usr/$account";
    exec($cmd);

    // Copy output data "transxpb"
    $cmd = "rm -r " . $_SERVER['DOCUMENT_ROOT'] . "/slmtk/usr/$account/transxpb/*";exec($cmd);
    $cmd = "rm -r " . $_SERVER['DOCUMENT_ROOT'] . "/slmtk/usr/$account/TextGrid_plm/*";exec($cmd);
    $cmd = "cp -R $slmtk_root$id/intermediate/transxpb/ " . $_SERVER['DOCUMENT_ROOT'] . "/slmtk/usr/$account/"; exec($cmd); // TextGrid
    $cmd = "cp -R $slmtk_root$id/out/TextGrid_plm/ " . $_SERVER['DOCUMENT_ROOT'] . "/slmtk/usr/$account/"; exec($cmd); // TextGrid

    $zip = new ZipArchive();
    $path = $_SERVER['DOCUMENT_ROOT'] . "/slmtk/usr/$account/";
    $fn_zip = $path . $account . "_5.zip";
    if (!($zip->open($fn_zip, ZipArchive::CREATE))) {
        exit("cannot open $fn_zip\n");
    }
    // Iterate folder
    // Add .TextGrid
    if ($handle = opendir($path . "TextGrid_plm")) {
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

    // Add .transxpb
    if ($handle = opendir($path . "transxpb")
    ) {
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
} else if ($usage == 7) {
    // Build user dir and copy file
    $cmd = "mkdir " . $_SERVER['DOCUMENT_ROOT'] . "/slmtk/usr/$account";
    exec($cmd);

    // Copy output data "transxpb"
    $cmd = "rm -r " . $_SERVER['DOCUMENT_ROOT'] . "/slmtk/usr/$account/test/*";
    exec($cmd);
    $cmd = "cp -R $slmtk_root$id/out/WOLRD_VOCODING_TUTORIAL/vocoding_scripts/feat_extraction/wav/test/ " . $_SERVER['DOCUMENT_ROOT'] . "/slmtk/usr/$account/";
    exec($cmd); // TextGrid
    $cmd = "cp -R $slmtk_root$id/out/HTS-demo_SLMTK_SAT/data/file_mapping.txt " . $_SERVER['DOCUMENT_ROOT'] . "/slmtk/usr/$account/";
    exec($cmd); // TextGrid

    $zip = new ZipArchive();
    $path = $_SERVER['DOCUMENT_ROOT'] . "/slmtk/usr/$account/";
    $fn_zip = $path . $account . "_5.zip";
    if (!($zip->open($fn_zip, ZipArchive::CREATE))) {
        exit("cannot open $fn_zip\n");
    }
    // Iterate folder
    // Add .TextGrid
    if ($handle = opendir($path . "test")) {
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

    $zip->addFile($path . "file_mapping.txt", "file_mapping.txt");
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
?>