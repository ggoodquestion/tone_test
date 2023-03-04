<?php

include('connect.php'); //連結資料庫
//判斷是否有submit操作
?>
<!DOCTYPE HTML>
<!--
	Landed by HTML5 UP
	html5up.net | @ajlkn
	Free for personal and commercial use under the CCA 3.0 license (html5up.net/license)
-->
<html>

<head>
	<title>Register</title>
	<meta charset="utf-8" />
	<meta name="viewport" content="width=device-width, initial-scale=1, user-scalable=no" />
	<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.0/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-KyZXEAg3QhqLMpG8r+8fhAXLRk2vvoC2f3B09zVXn8CA5QIVfZOJ3BCsw2P0p/We" crossorigin="anonymous">
	<link rel="stylesheet" href="../assets/css/main.css" />
	<link rel="stylesheet" href="../assets/css/my.css" />
	<noscript>
		<link rel="stylesheet" href="../assets/css/noscript.css" />
	</noscript>
</head>

<body class="is-preload">
	<style type="text/css">
		.form>* {
			margin: 1rem 0rem;
		}

		.form {
			padding: 10rem 35rem;
		}

		.actions {
			list-style-type: none;
			display: inline;
		}

		.match {
			border: 1px solid #00ff00;
		}

		.dismatch {
			border: 1px solid #ff0000;
		}
	</style>

	<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.1/dist/js/bootstrap.bundle.min.js" integrity="sha384-/bQdsTh/da6pkI1MST/rWKFNjaCP5gBSY4sEBT38Q/9RBh9AH40zEOg7Hlq2THRZ" crossorigin="anonymous"></script>

	<!-- Main -->
	<div id="main" class="wrapper style1">

		<!-- Form -->
		<section>
			<form method="post" action="index.php" class="form" id="form">
				<header class="major">
					<h2>Register</h2>
				</header>
				<input type="text" class="form-control" name="account" id="account" value="" placeholder="Username" onkeyup="checkAccountUnique()" required />
				<div class="text text-danger" id="checkAcc"></div>
				<input type="password" class="form-control" name="pwd" id="pwd" value="" placeholder="Password" required />
				<input type="password" class="form-control" name="pwd-comfirm" id="pwd_comfirm" value="" placeholder="Comfirm password" onkeyup="validate()" class="valid-pwd" required />
				<input type="email" class="form-control" name="email" id="name" value="" placeholder="Email" />
				<!-- <span style="display: inline;">
					<input class="form-check-input form-control" type="checkbox" id="termofservice" required>
					<label for="termofservice" class="text text-secondary">我已閱讀並同意<u><a data-bs-toggle="modal" data-bs-target="#modal-terms">服務條款</a></u></label>
				</span> -->
				<div class="actions">
					<input type="hidden" name="usage" value="signup" />
					<input class='btn btn-success' value="註冊" id="btnSub" type="submit"></input>
					<input type="reset" class='btn btn-danger' value="Reset" />
				</div>
		</section>

		</form>
		</section>
	</div>
	</div>

	<?php include "../terms.php"; ?>

	<!-- Scripts -->
	<script src="/js/jquery-3.6.0.min.js"></script>

	<script>
		function validate() {
			var pwd = document.getElementById("pwd");
			var pwd_comfirm = document.getElementById("pwd_comfirm");
			var pwd1 = pwd.value;
			var pwd2 = pwd_comfirm.value;
			var sub = document.getElementById("btnSub");
			if (pwd1 == pwd2) {
				pwd_comfirm.classList.add("match");
				pwd_comfirm.classList.remove("dismatch");
				sub.disabled = false;
			} else {
				pwd_comfirm.classList.add("dismatch");
				pwd_comfirm.classList.remove("match");

				sub.disabled = true;
			}
		}

		function checkAccountUnique() {
			$.post("./index.php", {
				usage: 'checkAcc',
				account: $('#account').val()
			}, function(data) {
				if (data.trim() != "ok" && data.trim() != "") {
					$('#account').addClass('dismatch');
					$('#account').removeClass('match');
					$('#btnSub').attr("disabled", 'disabled');
					$('#checkAcc').text(data);
				} else {
					$('#account').addClass('match');
					$('#account').removeClass('dismatch');
					$('#btnSub').removeAttr('disabled');
					$('#checkAcc').text('');
				}
			});
		}
	</script>
</body>

<?php
include '../templates/footer.php';
?>

</html>