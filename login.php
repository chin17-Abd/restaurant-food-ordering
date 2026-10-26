<?php
require "common.php";
if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $st = $conn->prepare("SELECT customer_id,full_name,email,password_hash FROM customers WHERE email=? AND is_active=1");
    $st->bind_param("s", $_POST['email']); $st->execute();
    $u = $st->get_result()->fetch_assoc();
    if ($u && password_verify($_POST['password'], $u['password_hash'])) {
        $_SESSION['pending'] = ['cid' => $u['customer_id'], 'name' => $u['full_name'], 'email' => $u['email']];
        $demo = send_otp($u['email'], $u['full_name']);
        flash($demo ? "Demo mode - your OTP is $demo" : "An OTP has been sent to your email.");
        header("Location: otp.php"); exit;
    }
    flash("Wrong email or password", true); header("Location: login.php"); exit;
}
top("Login"); ?>
<h2>Login</h2>
<form method="post" class="col">
<input type="email" name="email" placeholder="Email" required>
<input type="password" name="password" placeholder="Password" required>
<button>Login</button></form>
<p>New here? <a href="register.php">Create an account</a></p>
<?php bottom();
