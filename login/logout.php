<?php 
session_start();
unset($_SESSION['account']);
unset($_SESSION['login']) 
?>

<script>
	setTimeout(function() {
		window.location.href = '/index.php';
	}, 0);
</script>