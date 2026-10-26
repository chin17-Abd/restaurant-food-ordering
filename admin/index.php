<?php
require "../common.php";
define("ADMIN_PASS", "Abd@17");   // change this
if (isset($_GET['out'])) { unset($_SESSION['admin']); header("Location: ./"); exit; }
if (isset($_POST['pass'])) {
    if ($_POST['pass'] === ADMIN_PASS) $_SESSION['admin'] = 1; else flash("Wrong password", true);
    header("Location: ./"); exit;
}
if (empty($_SESSION['admin'])) {
    top("Admin", "../"); echo "<h2>Admin Login</h2><form method='post' class='col'><input type='password' name='pass' placeholder='Admin password' required><button>Login</button></form>"; bottom(); exit;
}
function nxt($s, $t){
    if ($s == 'PLACED') return 'CONFIRMED';
    if ($s == 'CONFIRMED') return 'PREPARING';
    if ($s == 'PREPARING') return $t == 'DELIVERY' ? 'OUT_FOR_DELIVERY' : 'DELIVERED';
    if ($s == 'OUT_FOR_DELIVERY') return 'DELIVERED';
    return null;
}
if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    try {
        $a = $_POST['a'] ?? '';
        if ($a == 'status') {
            $o = (int)$_POST['o']; $n = $_POST['n'];
            $st = $conn->prepare("CALL sp_update_order_status(?,?,NULL)"); $st->bind_param("is", $o, $n); $st->execute(); $st->close();
            flash("Order #$o is now $n");
        } elseif ($a == 'cancel') {
            $o = (int)$_POST['o']; $conn->query("CALL sp_cancel_order($o)"); flash("Order #$o cancelled");
        } elseif ($a == 'toggle') {
            $i = (int)$_POST['i']; $conn->query("UPDATE menu_items SET is_available=1-is_available WHERE item_id=$i"); flash("Item updated");
        } elseif ($a == 'add') {
            $c = (int)$_POST['cat']; $p = (float)$_POST['price']; $v = (int)$_POST['veg'];
            $st = $conn->prepare("INSERT INTO menu_items (category_id,name,description,price,is_veg) VALUES (?,?,?,?,?)");
            $st->bind_param("issdi", $c, $_POST['name'], $_POST['desc'], $p, $v); $st->execute(); flash("Item added");
        }
    } catch (mysqli_sql_exception $e) { flash($e->getMessage(), true); }
    header("Location: ?p=" . urlencode($_GET['p'] ?? 'orders')); exit;
}
$p = $_GET['p'] ?? 'orders';
top("Admin", "../");
echo "<div class='tabs'><a class='" . ($p == 'orders' ? 'on' : '') . "' href='?p=orders'>Orders</a><a class='" . ($p == 'menu' ? 'on' : '') . "' href='?p=menu'>Menu</a><a class='" . ($p == 'reports' ? 'on' : '') . "' href='?p=reports'>Reports</a><a class='" . ($p == 'bookings' ? 'on' : '') . "' href='?p=bookings'>Bookings</a><a href='../'>Site</a><a href='?out=1'>Logout</a></div>";
if ($p == 'orders') {
    echo "<h2>Orders</h2><table><tr><th>#</th><th>Customer</th><th>Restaurant</th><th>Type</th><th>Status</th><th>Total</th><th>Payment</th><th>Action</th></tr>";
    foreach ($conn->query("SELECT order_id,customer,restaurant,order_type,status,total_amount,method,payment_status FROM v_order_summary ORDER BY order_id DESC") as $o) {
        $n = nxt($o['status'], $o['order_type']);
        echo "<tr><td>{$o['order_id']}</td><td>" . h($o['customer']) . "</td><td>" . h($o['restaurant']) . "</td><td>{$o['order_type']}</td><td><b>{$o['status']}</b></td><td>₹{$o['total_amount']}</td><td>" . h($o['method'] . " " . $o['payment_status']) . "</td><td style='display:flex;gap:6px'>";
        if ($n) echo "<form method='post'><input type='hidden' name='a' value='status'><input type='hidden' name='o' value='{$o['order_id']}'><input type='hidden' name='n' value='$n'><button>→ $n</button></form>";
        if (in_array($o['status'], ['PLACED', 'CONFIRMED'])) echo "<form method='post'><input type='hidden' name='a' value='cancel'><input type='hidden' name='o' value='{$o['order_id']}'><button class='g'>Cancel</button></form>";
        echo "</td></tr>";
    }
    echo "</table>";
} elseif ($p == 'menu') {
    echo "<h2>Add menu item</h2><form method='post' class='card'><input type='hidden' name='a' value='add'><select name='cat'>";
    foreach ($conn->query("SELECT c.category_id,CONCAT(r.name,' - ',c.name) n FROM categories c JOIN restaurants r ON r.restaurant_id=c.restaurant_id") as $c) echo "<option value='{$c['category_id']}'>" . h($c['n']) . "</option>";
    echo "</select><input name='name' placeholder='Name' required><input name='desc' placeholder='Description'><input name='price' type='number' step='0.01' min='0' placeholder='Price' required><select name='veg'><option value='1'>Veg</option><option value='0'>Non-veg</option></select><button>Add</button></form>";
    echo "<h2>Menu items</h2><table><tr><th>Restaurant</th><th>Category</th><th>Item</th><th>Price</th><th>Available</th><th></th></tr>";
    foreach ($conn->query("SELECT m.item_id,r.name rn,c.name cn,m.name,m.price,m.is_available FROM menu_items m JOIN categories c ON c.category_id=m.category_id JOIN restaurants r ON r.restaurant_id=c.restaurant_id ORDER BY r.restaurant_id,c.category_id,m.item_id") as $m)
        echo "<tr><td>" . h($m['rn']) . "</td><td>" . h($m['cn']) . "</td><td>" . h($m['name']) . "</td><td>₹{$m['price']}</td><td>" . ($m['is_available'] ? "Yes" : "No") . "</td><td><form method='post'><input type='hidden' name='a' value='toggle'><input type='hidden' name='i' value='{$m['item_id']}'><button class='g'>Toggle</button></form></td></tr>";
    echo "</table>";
} elseif ($p == 'bookings') {
    echo "<h2>Upcoming bookings</h2>"; tbl($conn->query("SELECT * FROM v_upcoming_bookings"));
    echo "<h2>Reviews</h2>"; tbl($conn->query("SELECT r.name restaurant, v.rating, v.comment, v.created_at FROM reviews v JOIN restaurants r ON r.restaurant_id=v.restaurant_id ORDER BY v.review_id DESC"));
} else {
    echo "<h2>Daily sales</h2>"; tbl($conn->query("SELECT * FROM v_daily_sales"));
    echo "<h2>Top items</h2>"; tbl($conn->query("SELECT * FROM v_top_items ORDER BY units_sold DESC"));
    echo "<h2>Low stock</h2>"; tbl($conn->query("SELECT * FROM v_low_stock"));
    echo "<h2>Restaurants</h2>"; tbl($conn->query("SELECT * FROM v_restaurant_stats"));
}
bottom();
