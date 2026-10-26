<?php
require "common.php"; need_login();
$cid = (int)$_SESSION['cid'];
if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    try {
        $a = $_POST['a'] ?? '';
        if ($a == 'remove') {
            $i = (int)$_POST['item'];
            $st = $conn->prepare("DELETE FROM cart_items WHERE customer_id=? AND item_id=?");
            $st->bind_param("ii", $cid, $i); $st->execute();
        } elseif ($a == 'clear') {
            $conn->query("CALL sp_clear_cart($cid)");
        } elseif ($a == 'order') {
            $rest = (int)$_POST['rest'];
            $type = in_array($_POST['type'], ['PICKUP','DINE_IN']) ? $_POST['type'] : 'DELIVERY';
            $addr = $type == 'DELIVERY' ? (int)$_POST['addr'] : null;
            $coupon = trim($_POST['coupon']) ?: null;
            $method = $_POST['method']; $book = $type == 'DINE_IN' ? (int)$_POST['book'] : null;
            $st = $conn->prepare("CALL sp_place_order(?,?,?,?,?,?,?,@oid)");
            $st->bind_param("iiisssi", $cid, $rest, $addr, $type, $coupon, $method, $book);
            $st->execute(); $st->close();
            $oid = $conn->query("SELECT @oid")->fetch_row()[0];
            flash("Order #$oid placed successfully!"); header("Location: orders.php"); exit;
        }
    } catch (mysqli_sql_exception $e) { flash($e->getMessage(), true); }
    header("Location: cart.php"); exit;
}
$st = $conn->prepare("SELECT ci.item_id,m.name,m.price,ci.quantity,c.restaurant_id FROM cart_items ci JOIN menu_items m ON m.item_id=ci.item_id JOIN categories c ON c.category_id=m.category_id WHERE ci.customer_id=?");
$st->bind_param("i", $cid); $st->execute();
$items = $st->get_result()->fetch_all(MYSQLI_ASSOC);
top("Cart"); echo "<h2>Your Cart</h2>";
if (!$items) { echo "<p>Cart is empty. <a href='index.php'>Browse menu</a></p>"; bottom(); exit; }
$sub = 0;
foreach ($items as $i) {
    $line = $i['price'] * $i['quantity']; $sub += $line;
    echo "<form method='post' class='card'><div class='grow'><b>" . h($i['name']) . "</b> × {$i['quantity']}</div><span class='price'>₹" . number_format($line, 2) . "</span>
    <input type='hidden' name='a' value='remove'><input type='hidden' name='item' value='{$i['item_id']}'><button class='g'>Remove</button></form>";
}
echo "<p><b>Subtotal: ₹" . number_format($sub, 2) . "</b> <small>(tax and delivery fee added at checkout)</small></p>";
$addrs = $conn->query("SELECT address_id,label,street,city FROM addresses WHERE customer_id=$cid")->fetch_all(MYSQLI_ASSOC);
$bk = $conn->query("SELECT b.booking_id,b.booking_date,b.start_time,t.table_number FROM table_bookings b JOIN dining_tables t ON t.table_id=b.table_id WHERE b.customer_id=$cid AND b.status IN ('BOOKED','SEATED') AND t.restaurant_id=" . (int)$items[0]['restaurant_id'])->fetch_all(MYSQLI_ASSOC);
?>
<h3>Checkout</h3>
<form method="post" class="col">
<input type="hidden" name="a" value="order"><input type="hidden" name="rest" value="<?= (int)$items[0]['restaurant_id'] ?>">
<select name="type"><option value="DELIVERY">Delivery</option><option value="PICKUP">Pickup</option><option value="DINE_IN">Dine-in (needs a table booking)</option></select>
<select name="addr"><?php foreach ($addrs as $a) echo "<option value='{$a['address_id']}'>" . h($a['label'] . ": " . $a['street'] . ", " . $a['city']) . "</option>"; ?></select>
<select name="book"><option value="">Dine-in booking (only for dine-in)</option><?php foreach ($bk as $b) echo "<option value='{$b['booking_id']}'>Table " . h($b['table_number']) . " · " . h($b['booking_date']) . " " . h(substr($b['start_time'],0,5)) . "</option>"; ?></select>
<input name="coupon" placeholder="Coupon code (WELCOME10, SPICE50)">
<select name="method"><option>CASH</option><option>UPI</option><option>CARD</option><option>WALLET</option></select>
<button>Place Order</button></form>
<form method="post" style="margin-top:10px"><input type="hidden" name="a" value="clear"><button class="g">Clear cart</button></form>
<?php bottom();
