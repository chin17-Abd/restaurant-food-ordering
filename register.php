<?php
require "common.php";
if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    try {
        $hash = password_hash($_POST['password'], PASSWORD_DEFAULT);
        $st = $conn->prepare("INSERT INTO customers (full_name,email,phone,password_hash) VALUES (?,?,?,?)");
        $st->bind_param("ssss", $_POST['name'], $_POST['email'], $_POST['phone'], $hash); $st->execute();
        $cid = $conn->insert_id;
        $st = $conn->prepare("INSERT INTO addresses (customer_id,street,city,state,pincode,is_default) VALUES (?,?,?,?,?,1)");
        $st->bind_param("issss", $cid, $_POST['street'], $_POST['city'], $_POST['state'], $_POST['pincode']); $st->execute();
        $_SESSION['cid'] = $cid; $_SESSION['cname'] = $_POST['name'];
        flash("Welcome! Account created."); header("Location: index.php"); exit;
    } catch (mysqli_sql_exception $e) { flash("Could not register. Email/phone may already be used, or phone is not exactly 10 digits.", true); header("Location: register.php"); exit; }
}
top("Register"); ?>
<h2>Create account</h2>
<form method="post" class="col">
<input name="name" placeholder="Full name" required>
<input type="email" name="email" placeholder="Email" required>
<input name="phone" placeholder="Phone (10 digits)" pattern="[0-9]{10}" required>
<input type="password" name="password" placeholder="Password" minlength="6" required>
<input name="street" placeholder="Street address" required>
<input name="city" placeholder="City" required>
<input name="state" placeholder="State" value="West Bengal" required>
<input name="pincode" placeholder="Pincode" required>
<button>Register</button></form>
<?php bottom();
