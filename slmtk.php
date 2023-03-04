<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-1BmE4kWBq78iYhFldvKuhfTAU6auU8tT94WrHftjDbrCEXSU1oBoqyl2QvZ6jIW3" crossorigin="anonymous">
    <link rel="stylesheet" href="./css/main.css" />
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js" integrity="sha384-ka7Sk0Gln4gmtz2MlQnikT1wXgYsOg+OMhuP+IlRH9sENBO0LRn5q+8nbTov4+1p" crossorigin="anonymous"></script>
    <title>Speech Labeling & Modeling Toolkit</title>
</head>

<body>
    <style>
        .status {
            height: 2rem;
        }

        .uncheck {
            background-image: url("./images/radio_button_unchecked_black_24dp.svg");
            background-repeat: no-repeat;
            height: 2rem;
        }

        .check {
            background-image: url("./images/done_black_24dp.svg");
            background-repeat: no-repeat;
            height: 2rem;
        }

        .process {
            font-size: 1.25rem !important;
        }

        img {
            width: 33vw;
        }

        .emoji {
            width: 2rem;
        }

        .disappear {
            display: none;
        }

        #log-console {
            display: block;
            overflow: auto;
            border: 1px solid #282828;
            background: #000000;
            color: #eeeeee;
            height: 25rem;
        }
    </style>

    <?php include $_SERVER['DOCUMENT_ROOT'] . "/navbar.php"; ?>

    <div class="container process">
        <br />
        <ul class="nav nav-tabs" id="func" role="tablist">
            <li class="nav-item" role="presentation">
                <button class="nav-link active" id="main-tab" data-bs-toggle="tab" data-bs-target="#main" type="button" role="tab" aria-selected="true">Main</button>
            </li>
            <li class="nav-item" role="presentation">
                <button class="nav-link" id="tts-tab" data-bs-toggle="tab" data-bs-target="#tts" type="button" role="tab" aria-selected="false">TTS</button>
            </li>
        </ul>
        <div class=" tab-content">
            <div class="border p-5 tab-pane fade show active" id="main" role="tabpanel">
                <span>
                    <h2 align="center">SLMTK 1.0</h2>
                    <h4 class="text text-secondary" align="center">The Speech Labeling and Modeling Toolkit</h4>
                    <!-- <h4 class="text text-secondary" align="center">version<span class="badge bg-secondary">1.0</span></h4> -->
                </span>
                <form class="row" method="post" action="" id="slmtk0" enctype='multipart/form-data'>
                    <div class="input-group my-3 me-3">
                        <lable class="form-control mx-2">Upload zipped text files: text.zip:<input type="file" name="txtfile" id="txtfile" class="form-control" required></lable>
                        <lable class="form-control mx-2">Upload zipped wave files: wav.zip<input type="file" name="wavfile" id="wavfile" class="form-control" required></lable>
                        <button class="input-group-text mx-2 me-5 btn btn-outline-dark" type="submit">Upload</button>
                    </div>
                </form>
                <!-- <div class="progress">
                    <div class="progress-bar" role="progressbar" aria-valuenow="0" aria-valuemin="0" aria-valuemax="100"></div>
                </div> -->
                <div class="alert" id="show-stat"></div>
                <div class="row my-3">
                    <iuput type="button" class="col-1 uncheck" id="s0"></iuput>
                    <div class="col-9">0. initializing worksite</div>
                    <button id="btnFreq" class="disappear" type="hidden" data-bs-toggle="collapse" data-bs-target="#freqSetting" aria-expanded="false" aria-controls="freqSetting">
                    </button>
                    <div class="collapse" id="freqSetting">
                        <label class="input-group-text">LOWERF0HZ<input type="number" class="input-group" id="LOWERF0HZ" placeholder="ex:50" value="60"></label>
                        <label class="input-group-text">UPPERF0HZ<input type="number" class="input-group" id="UPPERF0HZ" placeholder="ex:330" value="550"></label>
                    </div>
                    <a href="/slmtk/download.php?usage=0" class="btn btn- btn-outline-success col-2" name="dl" id="dl0" for="0">Download</a>
                </div>
                <div class="row my-3">
                    <iuput type="button" class="col-1 uncheck" id="s1"></iuput>
                    <div class="col-9">1. Text Analysis (ta)</div>
                    <a href="/slmtk/download.php?usage=1" class="btn btn- btn-outline-success col-2" name="dl" id="dl1" for="1">Download</a>
                </div>
                <div class="row my-3">
                    <iuput type="button" class="col-1 uncheck" id="s2"></iuput>
                    <div class="col-9">2. Acoustic Feature Extraction (afe)</div>
                    <a href="/slmtk/download.php?usage=2" class="btn btn- btn-outline-success col-2" name="dl" id="dl2" for="2">Download</a>
                </div>
                <div class="row my-3">
                    <iuput type="button" class="col-1 uncheck" id="s3"></iuput>
                    <div class="col-9">3. Linguistic-Speech Alignment (lsa)</div>
                    <a href="/slmtk/download.php?usage=3" class="btn btn- btn-outline-success col-2" name="dl" id="dl3" for="3">Download</a>
                </div>
                <div class="row my-3">
                    <iuput type="button" class="col-1 uncheck" id="s4"></iuput>
                    <div class="col-9">4. Integration of Linguistic Features and Prosodic Features (ilp)</div>
                    <a href="/slmtk/download.php?usage=4" class="btn btn- btn-outline-success col-2" name="dl" id="dl4" for="4">Download</a>
                </div>
                <div class="row my-3">
                    <iuput type="button" class="col-1 uncheck" id="s5"></iuput>
                    <div class="col-9">5. Prosody Labeling and Modeling (plm)</div>
                    <a href="/slmtk/download.php?usage=5" class="btn btn- btn-outline-success col-2" name="dl" id="dl5" for="5">Download</a>
                </div>
                <div class="row my-3">
                    <iuput type="button" class="col-1 uncheck" id="s6"></iuput>
                    <div class="col-9">6. Construction of Prosody Generation Model (cpg)</div>
                    <a align="center" class="col-2" name="dl" id="dl6" for="6">Finish</a>
                </div>
                <div class="row my-3">
                    <iuput type="button" class="col-1 uncheck" id="s7"></iuput>
                    <div class="col-9">7. HTS Training (hts)</div>
                    <a class="btn btn- btn-outline-success col-2" name="dl" id="dl7" for="7">Download</a>
                </div>
                <div class="row my-5 d-flex justify-content-around">
                    <div class="btn btn-primary col-2 disabled" id="deploy">
                        <span class="spinner-border spinner-border-sm disappear" id="dspin" role="status" aria-hidden="true"></span>
                        Deploy
                    </div>
                    <div class="btn btn-primary col-2 disabled" id="next">
                        <span class="spinner-border spinner-border-sm disappear" id="spin" role="status" aria-hidden="true"></span>
                        Next
                    </div>
                </div>
                <div id="log-console">

                </div>
            </div>

            <div class="tab-pane fade" id="tts" role="tabpanel">
                <div class="container mt-5">
                    <div class="row">
                        <div class="col">
                            <textarea id="tts_input" class="form-control" placeholder="input text here..."></textarea>
                        </div>
                        <div class="col" id="tts_output">

                        </div>
                    </div>
                    <div class="row">
                        <div class="input-group ms-3 mt-3">
                            <select class="" id="tts_type">
                                <option selected>Select models</option>
                                <option value="1">HTS-SD</option>
                                <option value="2">HTS-SAT</option>
                            </select>
                            <button class="btn btn-primary" id="tts_submit">Speak</button>
                        </div>
                    </div>

                </div>

                <hr>
            </div>

        </div>

        <script type="text/javascript" src="/js/jquery-3.6.0.min.js"></script>
        <!-- <script src="/js/slmtk.js"></script> -->
        <script>
            $("a[name='dl']").each(function(index) {
                $(this).addClass("disappear");
            });

            var step = -1;
            var stepForLog = -1;
            var is_fin = true;
            var refreshLogId;

            <?php
            include $_SERVER['DOCUMENT_ROOT'] . '/login/connect.php';
            if (isset($_SESSION['account']) && $_SESSION['login'] == true) {
                $sql = "SELECT id, workspace FROM user WHERE account='" . $_SESSION['account'] . "';";
                $res = mysqli_query($con, $sql);
                if (!$res) exit("error:" . mysqli_error($con));
                $row = mysqli_fetch_array($res);
                $workspace = $row['workspace'];
                $id = $row['id'];
                echo "var uid = '" . $workspace . "';\n";
                echo "var id = '" . $id . "';\n";
            ?>

                refreshProgress = function() {
                    flag = true;
                    while (flag) {
                        $.get('/slmtk/workspace/' + uid + '/metadata.json', function(data) {
                            progress = data['progress'];
                            if (progress == 100) {
                                showFinish(step);
                                $("#next").removeClass("disabled");
                                step++;
                                flag = false;
                            }
                        });
                    }
                }
                if (uid != '') {
                    $.get('/slmtk/workspace/' + uid + '/metadata.json', function(data) {

                        step = data['step'];
                        var progress = data['progress'];
                        if (progress == 100) {
                            for (let i = 0; i <= step && i < 8; i++) {
                                showFinish(i);
                            }
                            $("#next").removeClass("disabled");
                            step++;
                            if (step == 8) {
                                $("#deploy").removeClass("disabled");
                            }
                        } else {

                        }
                    });
                }
            <?php
            }
            ?>

            checkStep();

            $("#slmtk0").submit(function(event) {
                event.preventDefault();

                // connectSocket();

                var fd = new FormData();
                var file1 = $('#txtfile').prop('files')[0];
                var file2 = $('#wavfile').prop('files')[0];
                fd.append('txtfile', file1);
                fd.append('wavfile', file2);

                $.ajax({
                    url: "/slmtk/upload.php",
                    data: fd,
                    cache: false,
                    processData: false,
                    contentType: false,
                    type: 'post',
                    success: function(data) {
                        if (data.trim() == "success") {
                            showSuccAlert("Upload successful");
                            $("#next").removeClass("disabled");
                            step = 0;
                            for (i = 0; i <= 6; i++) {
                                unFinish(i);
                            }
                            $("#freqSetting").addClass("show");
                        } else showFailAlert(data);

                    },
                    error: function(data) {
                        showFailAlert(data);
                    }
                });
            });

            $("#next").click(function() {
                setButton(false);
                $("#log-console").html("");
                stepForLog = step;

                if (step == 0) {
                    LOWFREQ = $("#LOWERF0HZ").val();
                    HIGHFREQ = $("#UPPERF0HZ").val();
                    $.post("/slmtk/" + step + ".php", {
                        lf: LOWFREQ,
                        hf: HIGHFREQ
                    }, function(data) {
                        setButton(true);
                        if (data.trim() == "success") {
                            if (step == 0) {
                                showSuccAlert("Initialize successful");
                                showFinish(step);
                                $("#freqSetting").removeClass("show");
                                step = step + 1;
                            }
                        } else {
                            showFailAlert(data);
                        }
                    });
                } else {
                    $.post("/slmtk/" + step + ".php", {

                    }, function(data) {
                        setButton(true);
                        if (data.trim() == "success") {
                            if (step == 1) {
                                showSuccAlert("Text Analysis successful");
                            } else if (step == 2) {
                                showSuccAlert("Acoustic Feature Extraction successful");
                            } else if (step == 3) {
                                showSuccAlert("Linguistic-Speech Alignment successful");
                            } else if (step == 4) {
                                showSuccAlert("Integration of Linguistic Features and Prosodic Features successful");
                            } else if (step == 5) {
                                showSuccAlert("Prosody Labeling and Modeling successful");
                            } else if (step == 6) {
                                showSuccAlert("Constrution of Prosody Generation Model successful");
                            } else if (step == 7) {
                                showSuccAlert("HTS Training successful");
                                $("#deploy").removeClass("disabled");
                            }
                            showFinish(step);
                            step = step + 1;
                        } else {
                            showFailAlert(data);
                        }
                    });
                }
                is_fin = false;
                refreshLogId = setInterval(getLog, 1000);
            });

            var getLog = function() {
                if (is_fin) return;
                $.post("/slmtk/show_log.php?usage=" + stepForLog + "&id=" + id, {}, function(data) {
                    $("#log-console").html(data);
                    lines = data.split("</br>");

                    final = lines[lines.length - 2];
                    let stat = final.match(/\[.*\]/)[0];
                    let progress = final.match(/\(\d+\/\d+\)/)[0].replace("(", "").replace(")", "");
                    console.log(progress);

                    if (stat == '[end]') {
                        let now = progress.split('/')[0];
                        let total = progress.split('/')[1];
                        if (now == total) {
                            is_fin = true;
                            clearInterval(refreshLogId);
                            checkStep();
                        }
                    }
                });
            }

            $("#deploy").click(function() {
                $("#log-console").html("");
                stepForLog = step;
                setDeployButton(false);

                // is_fin = false;
                // refreshLogId = setInterval(getLog, 1000);
                $.post("/slmtk/deploy.php", {

                }, function(data) {
                    showSuccAlert("Deploy successful");
                    step = step + 1;
                    setDeployButton(true);
                });
            });

            $("#tts_submit").click(function() {
                tts_type = $("#tts_type").val();
                if (tts_type == 1) {
                    tts_type = "hts_sd";
                } else if (tts_type == 2) {
                    tts_type = "hts_sat";
                } else {
                    alert("Please select models");
                    return;
                }

                tts_input = $("#tts_input").val();

                $.post("/slmtk/tts.php", {
                    input: tts_input,
                    type: tts_type
                }, function(data) {
                    $("#tts_output").html('<audio controls><source src="/slmtk/workspace/' + uid + '/convert/' + data + '" type="audio/wav"></audio>');
                });
            });

            function checkStep() {
                if (step == 8) {
                    $("#deploy").removeClass("disabled");
                }
            }

            function showSuccAlert(msg) {
                $("#show-stat").removeClass("alert-danger");
                $("#show-stat").addClass("alert-success");
                $("#show-stat").text(msg);
            }

            function showFailAlert(msg) {
                $("#show-stat").removeClass("alert-success");
                $("#show-stat").addClass("alert-danger");
                $("#show-stat").text(msg);
            }

            function showFinish(step) {
                $("#s" + step).removeClass("uncheck");
                $("#s" + step).addClass("check");
                $("#dl" + step).removeClass("disappear");
            }

            function unFinish(step) {
                $("#s" + step).addClass("uncheck");
                $("#s" + step).removeClass("check");
                $("#dl" + step).addClass("disappear");
            }

            function setButton(value) {
                if (value) {
                    $('#next').removeClass("disabled");
                    $('#spin').addClass("disappear");
                } else {
                    $('#next').addClass("disabled");
                    $('#spin').removeClass("disappear");
                }
            }

            function setDeployButton(value) {
                if (value) {
                    $('#deploy').removeClass("disabled");
                    $('#dspin').addClass("disappear");
                } else {
                    $('#deploy').addClass("disabled");
                    $('#dspin').removeClass("disappear");
                }
            }


            // $.ajax({
            //     url: "/slmtk/" + step + ".php",
            //     timeout: 3600000,
            //     success: function(data) {
            //         setButton(true);
            //         if (data.trim() == "success") {
            //             if (step == 0) {
            //                 showSuccAlert("初始化successful");
            //             } else if (step == 1) {
            //                 showSuccAlert("Text Analysis successful");
            //             } else if (step == 2) {
            //                 showSuccAlert("Speech Segmentation successful");
            //             } else if (step == 3) {
            //                 showSuccAlert("Integration of Linguistic Features and Prosodic Features successful");
            //             }
            //             showFinish(step);
            //             step = step + 1;
            //         } else {
            //             showFailAlert(data);
            //         }
            //     }
            // });
        </script>

</body>

</html>