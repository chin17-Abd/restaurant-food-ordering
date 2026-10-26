<?php
require "common.php"; need_login();
$cid = (int)$_SESSION['cid'];
if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    try {
        if (($_POST['a'] ?? '') == 'cancel') {
            $b = (int)$_POST['b'];
            $st = $conn->prepare("SELECT 1 FROM table_bookings WHERE booking_id=? AND customer_id=?");
            $st->bind_param("ii", $b, $cid); $st->execute();
            if ($st->get_result()->num_rows) { $conn->query("CALL sp_cancel_booking($b)"); flash("Booking cancelled"); }
        } else {
            $r = (int)$_POST['rest']; $g = (int)$_POST['guests']; $q = $_POST['req'] ?: null;
            $st = $conn->prepare("CALL sp_book_table(?,?,?,?,?,?,?,@bid)");
            $st->bind_param("iisssis", $cid, $r, $_POST['date'], $_POST['start'], $_POST['end'], $g, $q);
            $st->execute(); $st->close();
            flash("Table booked! Booking #" . $conn->query("SELECT @bid")->fetch_row()[0]);
        }
    } catch (mysqli_sql_exception $e) { flash($e->getMessage(), true); }
    header("Location: bookings.php"); exit;
}
top("Book a Table"); ?>
<h2>Book a table</h2>
<form method="post" class="col">
<select name="rest"><?php foreach ($conn->query("SELECT restaurant_id,name FROM restaurants WHERE is_active=1") as $r) echo "<option value='{$r['restaurant_id']}'>" . h($r['name']) . "</option>"; ?></select>
<input type="date" name="date" min="<?= date('Y-m-d') ?>" required>
<label>From <input type="time" name="start" required></label>
<label>To <input type="time" name="end" required></label>
<input type="number" name="guests" min="1" max="12" value="2" required>
<input name="req" placeholder="Special request (optional)">
<button>Book Table</button></form>
<h2>My bookings</h2>
<?php
$st = $conn->prepare("SELECT b.booking_id,r.name rn,t.table_number,b.booking_date,b.start_time,b.end_time,b.guests,b.status FROM table_bookings b JOIN dining_tables t ON t.table_id=b.table_id JOIN restaurants r ON r.restaurant_id=t.restaurant_id WHERE b.customer_id=? ORDER BY b.booking_date DESC,b.start_time DESC");
$st->bind_param("i", $cid); $st->execute(); $n = 0;
foreach ($st->get_result() as $b) {
    $n++;
    echo "<div class='card'><div class='grow'><b>Booking #{$b['booking_id']}</b> · " . h($b['rn']) . " · Table " . h($b['table_number']) . "<br><small>" . h($b['booking_date']) . " · " . h(substr($b['start_time'], 0, 5)) . "-" . h(substr($b['end_time'], 0, 5)) . " · " . (int)$b['guests'] . " guests</small></div><b>" . h($b['status']) . "</b>";
    if ($b['status'] == 'BOOKED') echo "<form method='post'><input type='hidden' name='a' value='cancel'><input type='hidden' name='b' value='{$b['booking_id']}'><button class='g'>Cancel</button></form>";
    echo "</div>";
}
if (!$n) echo "<p>No bookings yet.</p>";
bottom();
