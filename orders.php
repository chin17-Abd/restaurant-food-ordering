<?php
require "common.php"; need_login();
$cid = (int)$_SESSION['cid'];
if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    try {
        $o = (int)$_POST['o'];
        $st = $conn->prepare("SELECT restaurant_id FROM orders WHERE order_id=? AND customer_id=?");
        $st->bind_param("ii", $o, $cid); $st->execute();
        $own = $st->get_result()->fetch_assoc();
        if ($own && ($_POST['a'] ?? '') == 'review') {
            $rt = (int)$_POST['rating']; $rid = (int)$own['restaurant_id']; $cm = $_POST['comment'] ?: null;
            $st = $conn->prepare("INSERT INTO reviews (order_id,customer_id,restaurant_id,rating,comment) VALUES (?,?,?,?,?)");
            $st->bind_param("iiiis", $o, $cid, $rid, $rt, $cm); $st->execute();
            flash("Thanks for your review!");
        } elseif ($own) { $conn->query("CALL sp_cancel_order($o)"); flash("Order #$o cancelled"); }
    } catch (mysqli_sql_exception $e) { flash($e->getMessage(), true); }
    header("Location: orders.php"); exit;
}
$st = $conn->prepare("SELECT o.order_id,o.status,o.order_type,o.total_amount,o.placed_at,r.name rn,p.method,p.status ps,rv.rating,rv.comment,
 (SELECT GROUP_CONCAT(CONCAT(m.name,' x',oi.quantity) SEPARATOR ', ') FROM order_items oi JOIN menu_items m ON m.item_id=oi.item_id WHERE oi.order_id=o.order_id) items
 FROM orders o JOIN restaurants r ON r.restaurant_id=o.restaurant_id LEFT JOIN payments p ON p.order_id=o.order_id LEFT JOIN reviews rv ON rv.order_id=o.order_id WHERE o.customer_id=? ORDER BY o.order_id DESC");
$st->bind_param("i", $cid); $st->execute();
top("My Orders"); echo "<h2>My Orders</h2>"; $n = 0;
foreach ($st->get_result() as $o) {
    $n++;
    echo "<div class='card'><div class='grow'><b>Order #{$o['order_id']}</b> · " . h($o['rn']) . " · " . h($o['order_type']) . "<br><small>" . h($o['items']) . "</small><br>
    <small>" . h($o['placed_at']) . " · " . h($o['method']) . " (" . h($o['ps']) . ")</small></div>
    <span class='price'>₹" . h($o['total_amount']) . "</span><b>" . h($o['status']) . "</b>";
    if (in_array($o['status'], ['PLACED', 'CONFIRMED']))
        echo "<form method='post'><input type='hidden' name='o' value='{$o['order_id']}'><button class='g'>Cancel</button></form>";
    if ($o['status'] == 'DELIVERED') {
        if ($o['rating']) echo "<div style='width:100%'><span class='stars'>" . str_repeat("★", (int)$o['rating']) . str_repeat("☆", 5 - (int)$o['rating']) . "</span> <small>" . h($o['comment']) . "</small></div>";
        else echo "<form method='post' style='width:100%;display:flex;gap:8px;flex-wrap:wrap'><input type='hidden' name='a' value='review'><input type='hidden' name='o' value='{$o['order_id']}'>
        <select name='rating'><option value='5'>★★★★★ 5</option><option value='4'>★★★★ 4</option><option value='3'>★★★ 3</option><option value='2'>★★ 2</option><option value='1'>★ 1</option></select>
        <input name='comment' placeholder='Write a review' style='flex:1'><button>Review</button></form>";
    }
    echo "</div>";
}
if (!$n) echo "<p>No orders yet.</p>";
bottom();
