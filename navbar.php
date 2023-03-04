<?php session_start(); ?>
<nav class="navbar navbar-expand-lg navbar-light bg-light">
    <div class="container-fluid">
        <a class="navbar-brand" href="/">SLMTK</a>
        <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav" aria-controls="navbarNav" aria-expanded="false" aria-label="Toggle navigation">
            <span class="navbar-toggler-icon"></span>
        </button>
        <div class="collapse navbar-collapse" id="navbarNav">
            <ul class="navbar-nav me-auto">
                <li class="nav-item">
                    <a class="nav-link active" aria-current="page" href="/index.php">Home</a>
                </li>
                <li class="nav-item">
                    <a class="nav-link" href="/slmtk.php">SLMTK1.0</a>
                </li>
            </ul>
            <div class="d-flex">
                <?php
                if (isset($_SESSION['login']) && $_SESSION['login']) {
                    echo '<h5><span class="badge bg-secondary me-2">'.$_SESSION['account'].'</span></h5>';
                    echo '<a href="/login/logout.php" class="btn btn-success mx-1">Logout</a>';
                
                } else {
                    echo '<a href="/login/login.php" class="btn btn-success mx-1">Login</a>';
                    echo '<a href="/login/signup.php" class="btn btn-outline-primary mx-1">Register</a>';
                }
                ?>
            </div>
        </div>
    </div>
</nav>