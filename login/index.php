<?php
session_start();
$usage = $_POST['usage'];
include("connect.php");
$isSucc = true;
$msg = '';
switch ($usage) {
	case 'signup':
		$account = $_POST['account'];
		$password = $_POST['pwd'];
		$email = $_POST['email'];
		$pwd_hash = password_hash($password, PASSWORD_DEFAULT);
		$sql = "SELECT * FROM user WHERE account='$account';";
		$result = mysqli_query($con, $sql);
		if($result && $result->num_rows > 0) exit("This user is already exist"); 
		$sql = "INSERT INTO user(account, password, email) " .
			"VALUES ('$account', '$pwd_hash', '$email');";
		$result = mysqli_query($con, $sql);
		if (!$result) {
			echo mysqli_error($con);
			$isSucc = false;
			$msg = 'Register fail';
			exit("Register fail");
		}
		$sql = "SELECT id FROM user WHERE account='$account'";
		$result = mysqli_query($con, $sql);
		$_SESSION['id'] = mysqli_fetch_array($result)['id']+1;
		$isSucc = true;
		$msg = "Register successful";
		$_SESSION['login'] = true;
		$_SESSION['account'] = $account;
		break;
	case 'login':
		$account = $_POST['account'];
		$password = $_POST['pwd'];
		if($account == '' && $password == '') {
			exit("Username or password is required");
		}
		$sql = "SELECT id, password, enable FROM user WHERE account='$account';";
		$result = mysqli_query($con, $sql);
		if(!$result){
			exit("Login fail");
		}
		if($result->num_rows != 1){
			exit("Login fail : username or password are wrong");
		}
		$row = mysqli_fetch_array($result);
		$pwd_hash = $row['password'];
		if(!password_verify($password, $pwd_hash)){
			exit("Login fail : user is not exist or password is wrong");
		}
		$msg = "Login successful";
		$_SESSION['login'] = true;
		$_SESSION['account'] = $account;
		$_SESSION['id'] = $row['id'];
		$_SESSION['enable'] = $row['enable'];
		exit("Login successful");
		break;
	case 'checkAcc':
		$account = $_POST['account'];
		if ($account == '') exit();
		$sql = "SELECT * FROM user WHERE account='$account';";
		$result = mysqli_query($con, $sql);
		if (!$result) {
			exit("error". mysqli_error($con));
		}
		if ($result->num_rows > 0) {
			exit("This user is exist");
		}
		exit("ok");
		break;
		
	default:
		mysqli_close($con);
		break;
}
?>
<!DOCTYPE HTML>
<!--
	Landed by HTML5 UP
	html5up.net | @ajlkn
	Free for personal and commercial use under the CCA 3.0 license (html5up.net/license)
-->
<html>

<head>
	<title><?php echo $msg; ?></title>
	<meta charset="utf-8" />
	<meta name="viewport" content="width=device-width, initial-scale=1, user-scalable=no" />
	<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.0/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-KyZXEAg3QhqLMpG8r+8fhAXLRk2vvoC2f3B09zVXn8CA5QIVfZOJ3BCsw2P0p/We" crossorigin="anonymous">
	<link rel="stylesheet" href="../assets/css/main.css" />
	<noscript>
		<link rel="stylesheet" href="../assets/css/noscript.css" />
	</noscript>
</head>


<body class="is-preload">

	<!-- Main -->
	<div id="main" class="wrapper style1">
		<div class="container">
			<header class="major">
				<h2 class="text text-success"><?php echo $msg; ?></h2>
				<p>Redirecting</p>
			</header>
		</div>
	</div>

	<!-- Scripts -->
	<script src="/js/jquery-3.6.0.min.js"></script>

</body>

</html>

<script>
	setTimeout(function() {
		window.location.href = '/index.php';
	}, 3000);
</script>