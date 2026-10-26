
CREATE DATABASE IF NOT EXISTS `food_ordering` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE `food_ordering`;


CREATE TABLE `addresses` (
  `address_id` int(11) NOT NULL,
  `customer_id` int(11) NOT NULL,
  `label` varchar(30) NOT NULL DEFAULT 'Home',
  `street` varchar(200) NOT NULL,
  `city` varchar(60) NOT NULL,
  `state` varchar(60) NOT NULL,
  `pincode` varchar(10) NOT NULL,
  `is_default` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;



CREATE TABLE `cart_items` (
  `customer_id` int(11) NOT NULL,
  `item_id` int(11) NOT NULL,
  `quantity` int(11) NOT NULL CHECK (`quantity` > 0),
  `added_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;


CREATE TABLE `categories` (
  `category_id` int(11) NOT NULL,
  `restaurant_id` int(11) NOT NULL,
  `name` varchar(60) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;



CREATE TABLE `coupons` (
  `coupon_id` int(11) NOT NULL,
  `restaurant_id` int(11) DEFAULT NULL,
  `code` varchar(30) NOT NULL,
  `description` varchar(150) DEFAULT NULL,
  `discount_type` enum('PERCENT','FLAT') NOT NULL,
  `discount_value` decimal(8,2) NOT NULL CHECK (`discount_value` > 0),
  `min_order_amount` decimal(8,2) NOT NULL DEFAULT 0.00,
  `max_discount` decimal(8,2) DEFAULT NULL,
  `valid_from` date NOT NULL,
  `valid_to` date NOT NULL,
  `usage_limit` int(11) DEFAULT NULL,
  `times_used` int(11) NOT NULL DEFAULT 0,
  `is_active` tinyint(1) NOT NULL DEFAULT 1
) ;



CREATE TABLE `customers` (
  `customer_id` int(11) NOT NULL,
  `full_name` varchar(100) NOT NULL,
  `email` varchar(120) NOT NULL,
  `phone` varchar(15) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `loyalty_points` int(11) NOT NULL DEFAULT 0 CHECK (`loyalty_points` >= 0),
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ;



CREATE TABLE `delivery_partners` (
  `partner_id` int(11) NOT NULL,
  `full_name` varchar(100) NOT NULL,
  `phone` varchar(15) NOT NULL,
  `vehicle_no` varchar(20) DEFAULT NULL,
  `is_available` tinyint(1) NOT NULL DEFAULT 1
) ;


CREATE TABLE `dining_tables` (
  `table_id` int(11) NOT NULL,
  `restaurant_id` int(11) NOT NULL,
  `table_number` varchar(10) NOT NULL,
  `capacity` int(11) NOT NULL CHECK (`capacity` > 0),
  `is_active` tinyint(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;



CREATE TABLE `ingredients` (
  `ingredient_id` int(11) NOT NULL,
  `restaurant_id` int(11) NOT NULL,
  `name` varchar(80) NOT NULL,
  `unit` enum('g','kg','ml','l','pcs') NOT NULL DEFAULT 'g',
  `stock_qty` decimal(12,3) NOT NULL DEFAULT 0.000 CHECK (`stock_qty` >= 0),
  `reorder_level` decimal(12,3) NOT NULL DEFAULT 0.000,
  `cost_per_unit` decimal(8,4) NOT NULL DEFAULT 0.0000
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;


CREATE TABLE `menu_items` (
  `item_id` int(11) NOT NULL,
  `category_id` int(11) NOT NULL,
  `name` varchar(120) NOT NULL,
  `description` varchar(255) DEFAULT NULL,
  `price` decimal(8,2) NOT NULL CHECK (`price` >= 0),
  `is_veg` tinyint(1) NOT NULL DEFAULT 1,
  `is_available` tinyint(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;


CREATE TABLE `menu_item_ingredients` (
  `item_id` int(11) NOT NULL,
  `ingredient_id` int(11) NOT NULL,
  `qty_required` decimal(10,3) NOT NULL CHECK (`qty_required` > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;



CREATE TABLE `orders` (
  `order_id` int(11) NOT NULL,
  `customer_id` int(11) NOT NULL,
  `restaurant_id` int(11) NOT NULL,
  `address_id` int(11) DEFAULT NULL,
  `partner_id` int(11) DEFAULT NULL,
  `booking_id` int(11) DEFAULT NULL,
  `coupon_id` int(11) DEFAULT NULL,
  `order_type` enum('DELIVERY','PICKUP','DINE_IN') NOT NULL DEFAULT 'DELIVERY',
  `status` enum('PLACED','CONFIRMED','PREPARING','OUT_FOR_DELIVERY','DELIVERED','CANCELLED') NOT NULL DEFAULT 'PLACED',
  `subtotal` decimal(10,2) NOT NULL DEFAULT 0.00,
  `tax` decimal(10,2) NOT NULL DEFAULT 0.00,
  `delivery_fee` decimal(10,2) NOT NULL DEFAULT 0.00,
  `discount_amount` decimal(10,2) NOT NULL DEFAULT 0.00,
  `total_amount` decimal(10,2) NOT NULL DEFAULT 0.00 CHECK (`total_amount` >= 0),
  `placed_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `delivered_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;


DELIMITER $$
CREATE TRIGGER `trg_coupon_used` AFTER INSERT ON `orders` FOR EACH ROW BEGIN
    IF NEW.coupon_id IS NOT NULL THEN
        UPDATE coupons SET times_used = times_used + 1 WHERE coupon_id = NEW.coupon_id;
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_orders_history_ins` AFTER INSERT ON `orders` FOR EACH ROW BEGIN
    INSERT INTO order_status_history (order_id, old_status, new_status)
    VALUES (NEW.order_id, NULL, NEW.status);
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_orders_history_upd` AFTER UPDATE ON `orders` FOR EACH ROW BEGIN
    IF NEW.status <> OLD.status THEN
        INSERT INTO order_status_history (order_id, old_status, new_status)
        VALUES (NEW.order_id, OLD.status, NEW.status);
    END IF;
END
$$
DELIMITER ;



CREATE TABLE `order_items` (
  `order_item_id` int(11) NOT NULL,
  `order_id` int(11) NOT NULL,
  `item_id` int(11) NOT NULL,
  `quantity` int(11) NOT NULL CHECK (`quantity` > 0),
  `unit_price` decimal(8,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;


DELIMITER $$
CREATE TRIGGER `trg_deduct_stock` AFTER INSERT ON `order_items` FOR EACH ROW BEGIN
    INSERT INTO stock_movements (ingredient_id, change_qty, reason, order_id)
    SELECT mi.ingredient_id, -(mi.qty_required * NEW.quantity), 'ORDER', NEW.order_id
      FROM menu_item_ingredients mi
     WHERE mi.item_id = NEW.item_id;

    UPDATE ingredients i
      JOIN menu_item_ingredients mi ON mi.ingredient_id = i.ingredient_id
       SET i.stock_qty = i.stock_qty - (mi.qty_required * NEW.quantity)
     WHERE mi.item_id = NEW.item_id;
END
$$
DELIMITER ;

-

CREATE TABLE `order_status_history` (
  `history_id` int(11) NOT NULL,
  `order_id` int(11) NOT NULL,
  `old_status` varchar(20) DEFAULT NULL,
  `new_status` varchar(20) NOT NULL,
  `changed_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;



CREATE TABLE `payments` (
  `payment_id` int(11) NOT NULL,
  `order_id` int(11) NOT NULL,
  `method` enum('CASH','CARD','UPI','WALLET') NOT NULL,
  `status` enum('PENDING','PAID','FAILED','REFUNDED') NOT NULL DEFAULT 'PENDING',
  `amount` decimal(10,2) NOT NULL,
  `transaction_ref` varchar(60) DEFAULT NULL,
  `paid_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------



CREATE TABLE `restaurants` (
  `restaurant_id` int(11) NOT NULL,
  `name` varchar(120) NOT NULL,
  `cuisine_type` varchar(60) DEFAULT NULL,
  `phone` varchar(15) DEFAULT NULL,
  `street` varchar(200) DEFAULT NULL,
  `city` varchar(60) DEFAULT NULL,
  `pincode` varchar(10) DEFAULT NULL,
  `opening_time` time DEFAULT NULL,
  `closing_time` time DEFAULT NULL,
  `tax_rate` decimal(5,2) NOT NULL DEFAULT 5.00 CHECK (`tax_rate` between 0 and 100),
  `delivery_fee` decimal(8,2) NOT NULL DEFAULT 30.00 CHECK (`delivery_fee` >= 0),
  `min_order_amount` decimal(8,2) NOT NULL DEFAULT 0.00 CHECK (`min_order_amount` >= 0),
  `avg_rating` decimal(3,2) NOT NULL DEFAULT 0.00,
  `rating_count` int(11) NOT NULL DEFAULT 0,
  `is_active` tinyint(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;



CREATE TABLE `reviews` (
  `review_id` int(11) NOT NULL,
  `order_id` int(11) NOT NULL,
  `customer_id` int(11) NOT NULL,
  `restaurant_id` int(11) NOT NULL,
  `rating` tinyint(4) NOT NULL CHECK (`rating` between 1 and 5),
  `comment` varchar(500) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;


DELIMITER $$
CREATE TRIGGER `trg_review_rating` AFTER INSERT ON `reviews` FOR EACH ROW BEGIN
    UPDATE restaurants
       SET avg_rating   = (SELECT ROUND(AVG(rating), 2) FROM reviews WHERE restaurant_id = NEW.restaurant_id),
           rating_count = (SELECT COUNT(*)              FROM reviews WHERE restaurant_id = NEW.restaurant_id)
     WHERE restaurant_id = NEW.restaurant_id;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_review_validate` BEFORE INSERT ON `reviews` FOR EACH ROW BEGIN
    DECLARE v_status VARCHAR(20);
    DECLARE v_cust   INT;
    DECLARE v_rest   INT;
    SELECT status, customer_id, restaurant_id INTO v_status, v_cust, v_rest
      FROM orders WHERE order_id = NEW.order_id;
    IF v_status IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Order not found';
    END IF;
    IF v_status <> 'DELIVERED' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Only delivered orders can be reviewed';
    END IF;
    IF v_cust <> NEW.customer_id OR v_rest <> NEW.restaurant_id THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Review does not match the order';
    END IF;
END
$$
DELIMITER ;


CREATE TABLE `stock_movements` (
  `movement_id` int(11) NOT NULL,
  `ingredient_id` int(11) NOT NULL,
  `change_qty` decimal(12,3) NOT NULL,
  `reason` enum('PURCHASE','ORDER','WASTAGE','ADJUSTMENT') NOT NULL,
  `order_id` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;



CREATE TABLE `table_bookings` (
  `booking_id` int(11) NOT NULL,
  `customer_id` int(11) NOT NULL,
  `table_id` int(11) NOT NULL,
  `booking_date` date NOT NULL,
  `start_time` time NOT NULL,
  `end_time` time NOT NULL,
  `guests` int(11) NOT NULL CHECK (`guests` > 0),
  `status` enum('BOOKED','SEATED','COMPLETED','CANCELLED','NO_SHOW') NOT NULL DEFAULT 'BOOKED',
  `special_request` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;


DELIMITER $$
CREATE TRIGGER `trg_booking_validate` BEFORE INSERT ON `table_bookings` FOR EACH ROW BEGIN
    DECLARE v_cap INT;
    IF NEW.end_time <= NEW.start_time THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'End time must be after start time';
    END IF;
    SET v_cap = (SELECT capacity FROM dining_tables WHERE table_id = NEW.table_id);
    IF NEW.guests > v_cap THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Guests exceed table capacity';
    END IF;
    IF EXISTS (SELECT 1 FROM table_bookings
                WHERE table_id = NEW.table_id
                  AND booking_date = NEW.booking_date
                  AND status IN ('BOOKED','SEATED')
                  AND NEW.start_time < end_time
                  AND NEW.end_time   > start_time) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Table already booked for this time slot';
    END IF;
END
$$
DELIMITER ;


CREATE TABLE `v_customer_spend` (
`customer_id` int(11)
,`full_name` varchar(100)
,`loyalty_points` int(11)
,`delivered_orders` bigint(21)
,`total_spent` decimal(32,2)
);


CREATE TABLE `v_daily_sales` (
`sale_date` date
,`orders` bigint(21)
,`revenue` decimal(32,2)
);


CREATE TABLE `v_item_availability` (
`restaurant` varchar(120)
,`item` varchar(120)
,`portions_possible` bigint(14)
);


CREATE TABLE `v_low_stock` (
`restaurant` varchar(120)
,`ingredient` varchar(80)
,`stock_qty` decimal(12,3)
,`reorder_level` decimal(12,3)
,`unit` enum('g','kg','ml','l','pcs')
);


CREATE TABLE `v_menu` (
`restaurant` varchar(120)
,`category` varchar(60)
,`item` varchar(120)
,`price` decimal(8,2)
,`type` varchar(7)
);


CREATE TABLE `v_open_restaurants` (
`restaurant_id` int(11)
,`name` varchar(120)
,`cuisine_type` varchar(60)
,`opening_time` time
,`closing_time` time
,`avg_rating` decimal(3,2)
);


CREATE TABLE `v_order_summary` (
`order_id` int(11)
,`customer` varchar(100)
,`restaurant` varchar(120)
,`order_type` enum('DELIVERY','PICKUP','DINE_IN')
,`status` enum('PLACED','CONFIRMED','PREPARING','OUT_FOR_DELIVERY','DELIVERED','CANCELLED')
,`subtotal` decimal(10,2)
,`discount_amount` decimal(10,2)
,`tax` decimal(10,2)
,`delivery_fee` decimal(10,2)
,`total_amount` decimal(10,2)
,`method` enum('CASH','CARD','UPI','WALLET')
,`payment_status` enum('PENDING','PAID','FAILED','REFUNDED')
,`placed_at` timestamp
);


CREATE TABLE `v_restaurant_stats` (
`restaurant_id` int(11)
,`name` varchar(120)
,`avg_rating` decimal(3,2)
,`rating_count` int(11)
,`total_orders` bigint(21)
,`revenue` decimal(32,2)
);


CREATE TABLE `v_top_items` (
`item` varchar(120)
,`restaurant` varchar(120)
,`units_sold` decimal(32,0)
,`sales` decimal(40,2)
);


CREATE TABLE `v_upcoming_bookings` (
`booking_id` int(11)
,`customer` varchar(100)
,`restaurant` varchar(120)
,`table_number` varchar(10)
,`booking_date` date
,`start_time` time
,`end_time` time
,`guests` int(11)
,`status` enum('BOOKED','SEATED','COMPLETED','CANCELLED','NO_SHOW')
);


DROP TABLE IF EXISTS `v_customer_spend`;

CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW `v_customer_spend`  AS SELECT `cu`.`customer_id` AS `customer_id`, `cu`.`full_name` AS `full_name`, `cu`.`loyalty_points` AS `loyalty_points`, count(`o`.`order_id`) AS `delivered_orders`, ifnull(sum(`o`.`total_amount`),0) AS `total_spent` FROM (`customers` `cu` left join `orders` `o` on(`o`.`customer_id` = `cu`.`customer_id` and `o`.`status` = 'DELIVERED')) GROUP BY `cu`.`customer_id`, `cu`.`full_name`, `cu`.`loyalty_points` ;


DROP TABLE IF EXISTS `v_daily_sales`;

CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW `v_daily_sales`  AS SELECT cast(`orders`.`placed_at` as date) AS `sale_date`, count(0) AS `orders`, sum(`orders`.`total_amount`) AS `revenue` FROM `orders` WHERE `orders`.`status` = 'DELIVERED' GROUP BY cast(`orders`.`placed_at` as date) ;

-- --------------------------------------------------------


DROP TABLE IF EXISTS `v_item_availability`;

CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW `v_item_availability`  AS SELECT `r`.`name` AS `restaurant`, `m`.`name` AS `item`, min(floor(`i`.`stock_qty` / `mi`.`qty_required`)) AS `portions_possible` FROM ((((`menu_items` `m` join `categories` `c` on(`c`.`category_id` = `m`.`category_id`)) join `restaurants` `r` on(`r`.`restaurant_id` = `c`.`restaurant_id`)) join `menu_item_ingredients` `mi` on(`mi`.`item_id` = `m`.`item_id`)) join `ingredients` `i` on(`i`.`ingredient_id` = `mi`.`ingredient_id`)) GROUP BY `r`.`name`, `m`.`item_id`, `m`.`name` ;


DROP TABLE IF EXISTS `v_low_stock`;

CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW `v_low_stock`  AS SELECT `r`.`name` AS `restaurant`, `i`.`name` AS `ingredient`, `i`.`stock_qty` AS `stock_qty`, `i`.`reorder_level` AS `reorder_level`, `i`.`unit` AS `unit` FROM (`ingredients` `i` join `restaurants` `r` on(`r`.`restaurant_id` = `i`.`restaurant_id`)) WHERE `i`.`stock_qty` <= `i`.`reorder_level` ;


DROP TABLE IF EXISTS `v_menu`;

CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW `v_menu`  AS SELECT `r`.`name` AS `restaurant`, `c`.`name` AS `category`, `m`.`name` AS `item`, `m`.`price` AS `price`, if(`m`.`is_veg`,'Veg','Non-Veg') AS `type` FROM ((`menu_items` `m` join `categories` `c` on(`c`.`category_id` = `m`.`category_id`)) join `restaurants` `r` on(`r`.`restaurant_id` = `c`.`restaurant_id`)) WHERE `m`.`is_available` = 1 ;


DROP TABLE IF EXISTS `v_open_restaurants`;

CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW `v_open_restaurants`  AS SELECT `restaurants`.`restaurant_id` AS `restaurant_id`, `restaurants`.`name` AS `name`, `restaurants`.`cuisine_type` AS `cuisine_type`, `restaurants`.`opening_time` AS `opening_time`, `restaurants`.`closing_time` AS `closing_time`, `restaurants`.`avg_rating` AS `avg_rating` FROM `restaurants` WHERE `restaurants`.`is_active` = 1 AND curtime() between `restaurants`.`opening_time` and `restaurants`.`closing_time` ;


DROP TABLE IF EXISTS `v_order_summary`;

CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW `v_order_summary`  AS SELECT `o`.`order_id` AS `order_id`, `cu`.`full_name` AS `customer`, `r`.`name` AS `restaurant`, `o`.`order_type` AS `order_type`, `o`.`status` AS `status`, `o`.`subtotal` AS `subtotal`, `o`.`discount_amount` AS `discount_amount`, `o`.`tax` AS `tax`, `o`.`delivery_fee` AS `delivery_fee`, `o`.`total_amount` AS `total_amount`, `p`.`method` AS `method`, `p`.`status` AS `payment_status`, `o`.`placed_at` AS `placed_at` FROM (((`orders` `o` join `customers` `cu` on(`cu`.`customer_id` = `o`.`customer_id`)) join `restaurants` `r` on(`r`.`restaurant_id` = `o`.`restaurant_id`)) left join `payments` `p` on(`p`.`order_id` = `o`.`order_id`)) ;


DROP TABLE IF EXISTS `v_restaurant_stats`;

CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW `v_restaurant_stats`  AS SELECT `r`.`restaurant_id` AS `restaurant_id`, `r`.`name` AS `name`, `r`.`avg_rating` AS `avg_rating`, `r`.`rating_count` AS `rating_count`, count(`o`.`order_id`) AS `total_orders`, ifnull(sum(case when `o`.`status` = 'DELIVERED' then `o`.`total_amount` end),0) AS `revenue` FROM (`restaurants` `r` left join `orders` `o` on(`o`.`restaurant_id` = `r`.`restaurant_id`)) GROUP BY `r`.`restaurant_id`, `r`.`name`, `r`.`avg_rating`, `r`.`rating_count` ;


DROP TABLE IF EXISTS `v_top_items`;

CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW `v_top_items`  AS SELECT `m`.`name` AS `item`, `r`.`name` AS `restaurant`, sum(`oi`.`quantity`) AS `units_sold`, sum(`oi`.`quantity` * `oi`.`unit_price`) AS `sales` FROM ((((`order_items` `oi` join `orders` `o` on(`o`.`order_id` = `oi`.`order_id` and `o`.`status` <> 'CANCELLED')) join `menu_items` `m` on(`m`.`item_id` = `oi`.`item_id`)) join `categories` `c` on(`c`.`category_id` = `m`.`category_id`)) join `restaurants` `r` on(`r`.`restaurant_id` = `c`.`restaurant_id`)) GROUP BY `m`.`item_id`, `m`.`name`, `r`.`name` ;


DROP TABLE IF EXISTS `v_upcoming_bookings`;

CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW `v_upcoming_bookings`  AS SELECT `b`.`booking_id` AS `booking_id`, `cu`.`full_name` AS `customer`, `r`.`name` AS `restaurant`, `t`.`table_number` AS `table_number`, `b`.`booking_date` AS `booking_date`, `b`.`start_time` AS `start_time`, `b`.`end_time` AS `end_time`, `b`.`guests` AS `guests`, `b`.`status` AS `status` FROM (((`table_bookings` `b` join `customers` `cu` on(`cu`.`customer_id` = `b`.`customer_id`)) join `dining_tables` `t` on(`t`.`table_id` = `b`.`table_id`)) join `restaurants` `r` on(`r`.`restaurant_id` = `t`.`restaurant_id`)) WHERE `b`.`booking_date` >= curdate() AND `b`.`status` in ('BOOKED','SEATED') ;


ALTER TABLE `addresses`
  ADD PRIMARY KEY (`address_id`),
  ADD KEY `customer_id` (`customer_id`);


ALTER TABLE `cart_items`
  ADD PRIMARY KEY (`customer_id`,`item_id`),
  ADD KEY `item_id` (`item_id`);


ALTER TABLE `categories`
  ADD PRIMARY KEY (`category_id`),
  ADD UNIQUE KEY `restaurant_id` (`restaurant_id`,`name`);


ALTER TABLE `coupons`
  ADD PRIMARY KEY (`coupon_id`),
  ADD UNIQUE KEY `code` (`code`),
  ADD KEY `restaurant_id` (`restaurant_id`);
-
ALTER TABLE `customers`
  ADD PRIMARY KEY (`customer_id`),
  ADD UNIQUE KEY `email` (`email`),
  ADD UNIQUE KEY `phone` (`phone`);


ALTER TABLE `delivery_partners`
  ADD PRIMARY KEY (`partner_id`),
  ADD UNIQUE KEY `phone` (`phone`);


ALTER TABLE `dining_tables`
  ADD PRIMARY KEY (`table_id`),
  ADD UNIQUE KEY `restaurant_id` (`restaurant_id`,`table_number`);


ALTER TABLE `ingredients`
  ADD PRIMARY KEY (`ingredient_id`),
  ADD UNIQUE KEY `restaurant_id` (`restaurant_id`,`name`);


ALTER TABLE `menu_items`
  ADD PRIMARY KEY (`item_id`),
  ADD KEY `idx_menu_category` (`category_id`);


ALTER TABLE `menu_item_ingredients`
  ADD PRIMARY KEY (`item_id`,`ingredient_id`),
  ADD KEY `ingredient_id` (`ingredient_id`);


ALTER TABLE `orders`
  ADD PRIMARY KEY (`order_id`),
  ADD KEY `address_id` (`address_id`),
  ADD KEY `partner_id` (`partner_id`),
  ADD KEY `booking_id` (`booking_id`),
  ADD KEY `coupon_id` (`coupon_id`),
  ADD KEY `idx_orders_customer` (`customer_id`),
  ADD KEY `idx_orders_restaurant` (`restaurant_id`,`status`),
  ADD KEY `idx_orders_placed_at` (`placed_at`);


ALTER TABLE `order_items`
  ADD PRIMARY KEY (`order_item_id`),
  ADD KEY `order_id` (`order_id`),
  ADD KEY `item_id` (`item_id`);


ALTER TABLE `order_status_history`
  ADD PRIMARY KEY (`history_id`),
  ADD KEY `idx_history_order` (`order_id`);


ALTER TABLE `payments`
  ADD PRIMARY KEY (`payment_id`),
  ADD UNIQUE KEY `order_id` (`order_id`);


ALTER TABLE `restaurants`
  ADD PRIMARY KEY (`restaurant_id`);


ALTER TABLE `reviews`
  ADD PRIMARY KEY (`review_id`),
  ADD UNIQUE KEY `order_id` (`order_id`),
  ADD KEY `customer_id` (`customer_id`),
  ADD KEY `restaurant_id` (`restaurant_id`);


ALTER TABLE `stock_movements`
  ADD PRIMARY KEY (`movement_id`),
  ADD KEY `idx_stock_ingredient` (`ingredient_id`),
  ADD KEY `idx_stock_order` (`order_id`);


ALTER TABLE `table_bookings`
  ADD PRIMARY KEY (`booking_id`),
  ADD KEY `customer_id` (`customer_id`),
  ADD KEY `idx_bookings_slot` (`table_id`,`booking_date`,`status`);


ALTER TABLE `addresses`
  MODIFY `address_id` int(11) NOT NULL AUTO_INCREMENT;


ALTER TABLE `categories`
  MODIFY `category_id` int(11) NOT NULL AUTO_INCREMENT;


ALTER TABLE `coupons`
  MODIFY `coupon_id` int(11) NOT NULL AUTO_INCREMENT;


ALTER TABLE `customers`
  MODIFY `customer_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `delivery_partners`
--
ALTER TABLE `delivery_partners`
  MODIFY `partner_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `dining_tables`
--
ALTER TABLE `dining_tables`
  MODIFY `table_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `ingredients`
--
ALTER TABLE `ingredients`
  MODIFY `ingredient_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `menu_items`
--
ALTER TABLE `menu_items`
  MODIFY `item_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `orders`
--
ALTER TABLE `orders`
  MODIFY `order_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `order_items`
--
ALTER TABLE `order_items`
  MODIFY `order_item_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `order_status_history`
--
ALTER TABLE `order_status_history`
  MODIFY `history_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `payments`
--
ALTER TABLE `payments`
  MODIFY `payment_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `restaurants`
--
ALTER TABLE `restaurants`
  MODIFY `restaurant_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `reviews`
--
ALTER TABLE `reviews`
  MODIFY `review_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `stock_movements`
--
ALTER TABLE `stock_movements`
  MODIFY `movement_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `table_bookings`
--
ALTER TABLE `table_bookings`
  MODIFY `booking_id` int(11) NOT NULL AUTO_INCREMENT;


--
ALTER TABLE `addresses`
  ADD CONSTRAINT `addresses_ibfk_1` FOREIGN KEY (`customer_id`) REFERENCES `customers` (`customer_id`) ON DELETE CASCADE;

--
-- Constraints for table `cart_items`
--
ALTER TABLE `cart_items`
  ADD CONSTRAINT `cart_items_ibfk_1` FOREIGN KEY (`customer_id`) REFERENCES `customers` (`customer_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `cart_items_ibfk_2` FOREIGN KEY (`item_id`) REFERENCES `menu_items` (`item_id`) ON DELETE CASCADE;

--
-- Constraints for table `categories`
--
ALTER TABLE `categories`
  ADD CONSTRAINT `categories_ibfk_1` FOREIGN KEY (`restaurant_id`) REFERENCES `restaurants` (`restaurant_id`) ON DELETE CASCADE;

--
-- Constraints for table `coupons`
--
ALTER TABLE `coupons`
  ADD CONSTRAINT `coupons_ibfk_1` FOREIGN KEY (`restaurant_id`) REFERENCES `restaurants` (`restaurant_id`) ON DELETE CASCADE;

--
-- Constraints for table `dining_tables`
--
ALTER TABLE `dining_tables`
  ADD CONSTRAINT `dining_tables_ibfk_1` FOREIGN KEY (`restaurant_id`) REFERENCES `restaurants` (`restaurant_id`) ON DELETE CASCADE;


ALTER TABLE `ingredients`
  ADD CONSTRAINT `ingredients_ibfk_1` FOREIGN KEY (`restaurant_id`) REFERENCES `restaurants` (`restaurant_id`) ON DELETE CASCADE;


ALTER TABLE `menu_items`
  ADD CONSTRAINT `menu_items_ibfk_1` FOREIGN KEY (`category_id`) REFERENCES `categories` (`category_id`) ON DELETE CASCADE;


ALTER TABLE `menu_item_ingredients`
  ADD CONSTRAINT `menu_item_ingredients_ibfk_1` FOREIGN KEY (`item_id`) REFERENCES `menu_items` (`item_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `menu_item_ingredients_ibfk_2` FOREIGN KEY (`ingredient_id`) REFERENCES `ingredients` (`ingredient_id`) ON DELETE CASCADE;


ALTER TABLE `orders`
  ADD CONSTRAINT `orders_ibfk_1` FOREIGN KEY (`customer_id`) REFERENCES `customers` (`customer_id`),
  ADD CONSTRAINT `orders_ibfk_2` FOREIGN KEY (`restaurant_id`) REFERENCES `restaurants` (`restaurant_id`),
  ADD CONSTRAINT `orders_ibfk_3` FOREIGN KEY (`address_id`) REFERENCES `addresses` (`address_id`),
  ADD CONSTRAINT `orders_ibfk_4` FOREIGN KEY (`partner_id`) REFERENCES `delivery_partners` (`partner_id`),
  ADD CONSTRAINT `orders_ibfk_5` FOREIGN KEY (`booking_id`) REFERENCES `table_bookings` (`booking_id`),
  ADD CONSTRAINT `orders_ibfk_6` FOREIGN KEY (`coupon_id`) REFERENCES `coupons` (`coupon_id`);


ALTER TABLE `order_items`
  ADD CONSTRAINT `order_items_ibfk_1` FOREIGN KEY (`order_id`) REFERENCES `orders` (`order_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `order_items_ibfk_2` FOREIGN KEY (`item_id`) REFERENCES `menu_items` (`item_id`);


ALTER TABLE `order_status_history`
  ADD CONSTRAINT `order_status_history_ibfk_1` FOREIGN KEY (`order_id`) REFERENCES `orders` (`order_id`) ON DELETE CASCADE;


ALTER TABLE `payments`
  ADD CONSTRAINT `payments_ibfk_1` FOREIGN KEY (`order_id`) REFERENCES `orders` (`order_id`) ON DELETE CASCADE;


ALTER TABLE `reviews`
  ADD CONSTRAINT `reviews_ibfk_1` FOREIGN KEY (`order_id`) REFERENCES `orders` (`order_id`),
  ADD CONSTRAINT `reviews_ibfk_2` FOREIGN KEY (`customer_id`) REFERENCES `customers` (`customer_id`),
  ADD CONSTRAINT `reviews_ibfk_3` FOREIGN KEY (`restaurant_id`) REFERENCES `restaurants` (`restaurant_id`);


ALTER TABLE `stock_movements`
  ADD CONSTRAINT `stock_movements_ibfk_1` FOREIGN KEY (`ingredient_id`) REFERENCES `ingredients` (`ingredient_id`) ON DELETE CASCADE;


ALTER TABLE `table_bookings`
  ADD CONSTRAINT `table_bookings_ibfk_1` FOREIGN KEY (`customer_id`) REFERENCES `customers` (`customer_id`),
  ADD CONSTRAINT `table_bookings_ibfk_2` FOREIGN KEY (`table_id`) REFERENCES `dining_tables` (`table_id`);

