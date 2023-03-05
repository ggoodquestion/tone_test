<?php session_start(); ?>
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-1BmE4kWBq78iYhFldvKuhfTAU6auU8tT94WrHftjDbrCEXSU1oBoqyl2QvZ6jIW3" crossorigin="anonymous">
    <link rel="stylesheet" href="/css/main.css" />
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js" integrity="sha384-ka7Sk0Gln4gmtz2MlQnikT1wXgYsOg+OMhuP+IlRH9sENBO0LRn5q+8nbTov4+1p" crossorigin="anonymous"></script>
    <title>Speech Labeling & Modeling Toolkit</title>
</head>

<body>
    <!-- Scripts -->
    <script src="/js/jquery-3.6.0.min.js"></script>
    <style>
        .status {
            height: 2rem;
        }

        .uncheck {
            background-image: url("./images/radio_button_unchecked_black_24dp.svg");
            background-repeat: no-repeat;
            height: 2rem;
        }

        img {
            width: 33vw;
        }

        .form>* {
            margin: 1rem 0rem;
        }

        .section {
            padding: 3.5rem 20rem;
        }

        .dropdown-menu {
            overflow-y: scroll;
            height: 50vh;
        }
    </style>

    <?php include $_SERVER['DOCUMENT_ROOT'] . "/navbar.php"; ?>

    <br />
    <div class="container" style="height: 90vh;">
        <div id="doc" class="container-fluid markdown-body comment-enabled" data-hard-breaks="true">
            <h1 class="part" data-startline="7" data-endline="7" id="-語音暨多媒體訊號處理實驗室-" data-id="-語音暨多媒體訊號處理實驗室-"><a class="anchor hidden-xs" href="#-語音暨多媒體訊號處理實驗室-" title="-語音暨多媒體訊號處理實驗室-" smoothhashscroll=""><span class="octicon octicon-link"></span></a>
                <center><span data-position="113" data-size="15"></span></center>
            </h1>
            <section class="section">

                <?php
                if (isset($_SESSION['login']) && $_SESSION['login']) {
                    include("survey.php");
                } else {
                ?>
                    <!-- Form -->
                    <h1 class="align-middle">Tone Perception Test</h1>
                    <h2 class="text-danger">請先登入</h2>
                    <form method="post" action="#" class="container form">
                        <header class="">
                            <h2>Login</h2>
                        </header>
                        <input class="form-control" type="text" name="account" id="account" value="" placeholder="Username" />
                        <input class="form-control" type="password" name="password" id="pwd" value="" placeholder="Password" />
                        <div class="text text-danger" id="err_msg"></div>
                        <input class="form-control btn btn-success" type="button" name="name" id="login" class="btn primary" value="Login" />
                    </form>
                    <script src="/js/login.js"></script>
                <?php
                }
                ?>
            </section>
        </div>
    </div>
</body>

</html>