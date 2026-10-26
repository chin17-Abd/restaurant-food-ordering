<?php
require "common.php";
$rests = $conn->query("SELECT restaurant_id,name,cuisine_type,delivery_fee,min_order_amount,avg_rating FROM restaurants WHERE is_active=1")->fetch_all(MYSQLI_ASSOC);
$rid = (int)($_GET['r'] ?? ($rests[0]['restaurant_id'] ?? 0));
if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    need_login();
    try {
        $cid = (int)$_SESSION['cid']; $iid = (int)$_POST['item']; $q = max(1, (int)$_POST['qty']);
        $st = $conn->prepare("CALL sp_add_to_cart(?,?,?)");
        $st->bind_param("iii", $cid, $iid, $q); $st->execute(); $st->close();
        flash("Added to cart");
    } catch (mysqli_sql_exception $e) { flash($e->getMessage(), true); }
    header("Location: index.php?r=$rid"); exit;
}
top("Menu");
echo "<div class='hero'><h1>Hungry? We've got you 🍛</h1><p>Order online or reserve a table in seconds.</p></div>";
echo "<div class='tabs'>";
foreach ($rests as $r) echo "<a class='" . ($r['restaurant_id'] == $rid ? "on" : "") . "' href='?r={$r['restaurant_id']}'>" . h($r['name']) . "</a>";
echo "</div>";
foreach ($rests as $r) if ($r['restaurant_id'] == $rid)
    echo "<p>" . h($r['cuisine_type']) . " · ⭐ " . h($r['avg_rating']) . " · Delivery ₹" . h($r['delivery_fee']) . " · Min order ₹" . h($r['min_order_amount']) . "</p>";
$st = $conn->prepare("SELECT c.name cat,m.item_id,m.name,m.description,m.price,m.is_veg FROM menu_items m JOIN categories c ON c.category_id=m.category_id WHERE c.restaurant_id=? AND m.is_available=1 ORDER BY c.category_id,m.item_id");
$st->bind_param("i", $rid); $st->execute();
$cat = "";
foreach ($st->get_result() as $m) {
    if ($m['cat'] != $cat) { $cat = $m['cat']; echo "<h3>" . h($cat) . "</h3>"; }
    echo "<form method='post' class='card'><div class='grow'>" . ($m['is_veg'] ? "🟢" : "🔴") . " <b>" . h($m['name']) . "</b><br><small>" . h($m['description']) . "</small></div>
    <span class='price'>₹" . h($m['price']) . "</span><input type='hidden' name='item' value='{$m['item_id']}'>
    <input type='number' name='qty' value='1' min='1' max='20' style='width:60px'><button>Add</button></form>";
}
bottom();
