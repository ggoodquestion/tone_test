<?php session_start(); ?>
<!DOCTYPE HTML>
<!--
	Landed by HTML5 UP
	html5up.net | @ajlkn
	Free for personal and commercial use under the CCA 3.0 license (html5up.net/license)
-->
<html>

<head>
    <title>登入</title>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, user-scalable=no" />
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.0/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-KyZXEAg3QhqLMpG8r+8fhAXLRk2vvoC2f3B09zVXn8CA5QIVfZOJ3BCsw2P0p/We" crossorigin="anonymous">
</head>

<body class="is-preload">

    <style type="text/css">
        .form>* {
            margin: 1rem 0rem;
        }

        .form {
            padding: 15rem 30rem;
        }
    </style>

    <!-- Main -->
    <div class="container">
        <!-- Form -->
        <section>
            <form method="post" action="#" class="container form">
                <header class="">
                    <h2>Login</h2>
                </header>
                <input class="form-control" type="text" name="account" id="account" value="" placeholder="Username" />
                <input class="form-control" type="password" name="password" id="pwd" value="" placeholder="Password" />
                <div class="text text-danger" id="err_msg"></div>
                <input class="form-control btn btn-success" type="button" name="name" id="login" class="btn primary" value="Login" />
            </form>
        </section>
    </div>

    <!-- Scripts -->
    <script src="/js/jquery-3.6.0.min.js"></script>

    <script>
        $('#login').click(function() {
            $.post('/login/index.php', {
                usage: 'login',
                account: $('#account').val(),
                pwd: $('#pwd').val()
            }, function(data) {
                $('#err_msg').html(data);
                if (data.includes('Login successful')) {
                    window.location.href = "/index.php";
                } else {
                    $('#err_msg').attr("class", "text text-danger");
                }
            });
        })
    </script>
</body>

</html>