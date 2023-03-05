<div>

    <?php
    $sn = $_GET['sn']; // Serial number

    $linecount = count(file("doc/samplesQ.csv")) - 1;

    if ($sn == '') {
        echo '<h1 class="align-middle">Tone Perception Test</h1>';
        echo "<h3>以下問題會有一個音檔與其文本，請依照題目回答是與否</h3>";
        echo '<a class="btn btn-success" href="./index.php?sn=1">Start!</a>';
        exit();
    }

    if ($sn == 0) {
        echo "<h2>謝謝完成本問卷</h2>";
        exit();
    }

    include('connect.php');
    $row = intval($sn);
    if (($handle = fopen("doc/samplesQ.csv", "r")) !== FALSE) {
        while (($data = fgetcsv($handle, 1000, ",")) !== FALSE && $row != 0) {
            $row--;
        }

        $wav = $data[0];
        $txt = $data[1];
        $qes = $data[2];

        $sql = "SELECT sn, content FROM question WHERE user_id=" . $_SESSION['id'] . " ORDER BY sn;";
        $res = mysqli_query($con, $sql);
        if (!$res) {
            exit("Loading error");
        }
        $finished = array();
        $unfinished = range(1, $linecount);
        while ($r = mysqli_fetch_array($res)) {
            array_push($finished, $r);
            $pos = array_search($r['sn'], $unfinished);
            array_splice($unfinished, $pos, 1);
        }

        echo '<div class="d-flex justify-content-between">';
        echo "<h1 class='text-primary'>第 $sn 題</h1>";
        echo '<span>';
    ?>
        <div class="dropdown">
            <button class="btn btn-outline-dark dropdown-toggle" type="button" data-bs-toggle="dropdown">
                已完成 <span class="badge bg-danger"><?php echo count($finished) ?></span>
            </button>
            <ul class="dropdown-menu">
                <?php
                foreach ($finished as $r) {
                    echo "<li><a class='dropdown-item' href='index.php?sn=" . $r['sn'] . "'>第" . $r['sn'] . "題 " . $r['content'] . "</a></li>";
                }
                ?>
            </ul>
        </div>
        <span> </span>
        <div class="dropdown">
            <button class="btn btn-outline-dark dropdown-toggle" type="button" data-bs-toggle="dropdown">
                未完成 <span class="badge bg-danger"><?php echo count($unfinished) ?></span>
            </button>
            <ul class="dropdown-menu">
                <?php
                foreach ($unfinished as $r) {
                    echo "<li><a class='dropdown-item' href='index.php?sn=$r'>第$r 題 </a></li>";
                }
                ?>
            </ul>
        </div>
        <?php

        // echo '<select class="form-select" id="finished"><span class="badge bg-secondary">New</span>';
        // echo '<option selected>已完成</option>';

        // echo '</select>';
        // echo '<select class="form-select" id="unfinished">';
        // echo '<option selected>未完成<span class="badge bg-secondary">New</option>';

        // foreach ($unfinished as $n) {
        //     echo "<option value='" . $n . "'>第" . $n . "題</option>";
        // }
        // echo '</select>';
        echo '</span>';
        echo '</div>'
        ?>

    <?php
        // echo "<h1 class='text-primary'>第 $sn 題</h1>";
        echo "<h2>文本：$txt</h2>";
        echo "<audio controls src='$wav'></audio>";
        echo "<hr/><span></span>";
        echo "<h2>Q: $qes</h2>";
        echo "<br/><span></span>";

        fclose($handle);
    }

    // Get if already have a record
    $id = $_SESSION['id'];

    $sql = "SELECT ans FROM question WHERE sn = $sn AND user_id = $id;";
    $res = mysqli_query($con, $sql);
    if ($res) $ans = mysqli_fetch_array($res)['ans'];

    ?>
    <form method="post" action="#">
        <div class="form-check">
            <?php
            if ($ans == 2) echo '<input class="form-check-input" type="radio" name="opt" id="yes" value="2" checked>';
            else echo '<input class="form-check-input" type="radio" name="opt" value="2" id="yes">';
            ?>
            <label class="form-check-label">
                YES
            </label>
        </div>
        <div class="form-check">
            <?php
            if ($ans == 3) echo '<input class="form-check-input" type="radio" name="opt" id="no" value="3" checked>';
            else echo '<input class="form-check-input" type="radio" name="opt" value="3" id="no">';
            ?>
            <label class="form-check-label">
                NO
            </label>
        </div>
    </form>

    <hr />
    <div class="d-flex justify-content-between">
        <div><input type="image" src="img/west_black_24dp.svg" id="pre-page"></div>
        <div><input type="button" class="btn btn-success" value="Submit" id="submit"></div>
        <div><input type="image" src="img/east_black_24dp.svg" id="next-page"></input></div>
    </div>
</div>

<script>
    sn = <?php echo $sn ?>;
    user = '<?php echo $_SESSION['account'] ?>';
    id = <?php echo $_SESSION['id'] ?>;
    wav = '<?php echo $data[0] ?>';
    txt = '<?php echo $data[1] ?>';
    qes = '<?php echo $data[2] ?>';

    linecount = <?php echo $linecount ?>

    $("#submit").click(function() {
        ans = $('input[name="opt"]:checked').val();
        if (ans == '') {
            alert('Please select a option.');
            return;
        }
        $.post('post.php', {
            sn: sn,
            user: user,
            id: id,
            wav: wav,
            txt: txt,
            qes: qes,
            ans: ans
        }, function(data) {
            json = JSON.parse(data);
            nxt = sn + 1;
            if (json['state'] == 'success') {
                if (sn == linecount) {
                    window.location.href = './index.php?sn=0';
                } else {
                    window.location.href = './index.php?sn=' + nxt.toString();
                }
            } else {
                alert(json['msg']);
            }
        });
    });

    $('#pre-page').click(function() {
        if (sn == 1) return;
        pre = sn - 1;
        window.location.href = './index.php?sn=' + pre.toString();
    });

    $('#next-page').click(function() {
        nxt = sn + 1;
        if (sn == linecount) {
            window.location.href = './index.php?sn=0';
        } else {
            window.location.href = './index.php?sn=' + nxt.toString();
        }
    });

    selectQes = function(e) {
        var opt = $('option:selected', this);
        val = opt.val();
        if (!isNaN(val)) {
            window.location.href = './index.php?sn=' + val.toString();
        }
    };

    $('#unfinished').on('change', '', selectQes);
    $('#finished').on('change', '', selectQes);
</script>