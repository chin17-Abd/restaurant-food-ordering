<?php
session_start();
require __DIR__ . "/db.php";
function h($s){ return htmlspecialchars((string)$s, ENT_QUOTES, 'UTF-8'); }
function flash($m, $e = false){ $_SESSION['flash'] = [$m, $e]; }
function need_login(){ if (empty($_SESSION['cid'])) { header("Location: login.php"); exit; } }
function top($t, $b = ""){
    echo "<!DOCTYPE html><html><head><meta charset='utf-8'><meta name='viewport' content='width=device-width,initial-scale=1'><title>" . h($t) . "</title><link rel='stylesheet' href='{$b}style.css'></head><body><nav><b>🍽 FoodOrder</b>";
    if ($b === "") {
        echo "<a href='index.php'>Menu</a><a href='bookings.php'>Book Table</a><a href='cart.php'>Cart</a>";
        if (!empty($_SESSION['cid'])) echo "<a href='orders.php'>My Orders</a><a href='logout.php'>Logout (" . h($_SESSION['cname']) . ")</a>";
        else echo "<a href='login.php'>Login</a><a href='register.php'>Register</a>";
        echo "<a href='admin/'>Admin</a>";
    }
    echo "</nav><div class='wrap'>";
    if (!empty($_SESSION['flash'])) {
        [$m, $e] = $_SESSION['flash'];
        echo "<div class='msg " . ($e ? "err" : "ok") . "'>" . h($m) . "</div>";
        unset($_SESSION['flash']);
    }
}
function bottom(){ echo "</div></body></html>"; }
function tbl($res){
    if (!$res->num_rows) { echo "<p>No data yet.</p>"; return; }
    echo "<table><tr>";
    foreach ($res->fetch_fields() as $f) echo "<th>" . h($f->name) . "</th>";
    echo "</tr>";
    while ($r = $res->fetch_row()) { echo "<tr>"; foreach ($r as $v) echo "<td>" . h($v) . "</td>"; echo "</tr>"; }
    echo "</table>";
}

// ---------- OTP ----------
define("OTP_DEMO", true);   // true = show the OTP on screen (local testing). Set to false once real email works.
function send_otp($email, $name){
    $otp = (string)random_int(100000, 999999);
    $_SESSION['otp'] = ['hash' => hash('sha256', $otp), 'exp' => time() + 300, 'tries' => 0, 'sent' => time()];
    @mail($email, "Your FoodOrder login OTP", "Hi $name,\n\nYour OTP is $otp. It is valid for 5 minutes.\nDo not share it with anyone.", "From: noreply@foodorder.local");
    return OTP_DEMO ? $otp : null;
}
