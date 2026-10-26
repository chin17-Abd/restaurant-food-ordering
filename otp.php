<?php
require "common.php";
if (empty($_SESSION['pending'])) { header("Location: login.php"); exit; }
$p = $_SESSION['pending'];
if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    if (isset($_POST['resend'])) {
        if (time() - ($_SESSION['otp']['sent'] ?? 0) < 30) flash("Please wait 30 seconds before resending.", true);
        else { $d = send_otp($p['email'], $p['name']); flash($d ? "Demo mode - your new OTP is $d" : "A new OTP has been sent."); }
    } else {
        $o = $_SESSION['otp'] ?? null;
        if (!$o || time() > $o['exp']) flash("OTP expired. Please click Resend OTP.", true);
        elseif ($o['tries'] >= 5) { unset($_SESSION['pending'], $_SESSION['otp']); flash("Too many wrong attempts. Please login again.", true); header("Location: login.php"); exit; }
        elseif (hash_equals($o['hash'], hash('sha256', trim($_POST['otp'])))) {
            session_regenerate_id(true);
            $_SESSION['cid'] = $p['cid']; $_SESSION['cname'] = $p['name'];
            unset($_SESSION['pending'], $_SESSION['otp']);
            header("Location: index.php"); exit;
        } else { $_SESSION['otp']['tries']++; flash("Wrong OTP. Try again.", true); }
    }
    header("Location: otp.php"); exit;
}
[$u, $d] = explode("@", $p['email']);
top("Verify OTP"); ?>
<h2>Enter OTP</h2>
<p>We sent a 6-digit code to <b><?= h(substr($u, 0, 2)) ?>***@<?= h($d) ?></b>. It is valid for 5 minutes.</p>
<form method="post" class="col">
<input name="otp" placeholder="6-digit OTP" inputmode="numeric" pattern="[0-9]{6}" maxlength="6" autofocus required>
<button>Verify &amp; Login</button></form>
<form method="post" style="margin-top:10px"><input type="hidden" name="resend" value="1"><button class="g" formnovalidate>Resend OTP</button></form>
<p><a href="login.php">Back to login</a></p>
<?php bottom();
