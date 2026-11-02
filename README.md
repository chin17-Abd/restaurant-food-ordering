<div align="center">

# Restaurant Food Ordering

**A PHP and MySQL web app for restaurant menus, online orders, and table bookings.**

[![PHP](https://img.shields.io/badge/PHP-mysqli-777BB4?logo=php&logoColor=white)](https://www.php.net/)
[![MySQL](https://img.shields.io/badge/Database-MySQL-4479A1?logo=mysql&logoColor=white)](https://www.mysql.com/)
[![Repository](https://img.shields.io/badge/GitHub-Repository-181717?logo=github)](https://github.com/chin17-Abd/restaurant-food-ordering)

</div>

---

## Overview

Restaurant Food Ordering is a server-rendered application for browsing restaurant menus, placing orders, and reserving tables. Customers can manage their orders and bookings, while administrators can manage menu availability and order progress.

> **Project status:** The source code and database schema are included. No seed data is provided, so add appropriate restaurant and menu data before using the app.

## Features

| Area | Capabilities |
| --- | --- |
| Customer accounts | Registration, password-based login, and email OTP verification |
| Restaurant menu | Browse active restaurants and available menu items |
| Cart and checkout | Manage cart items and place delivery, pickup, or dine-in orders |
| Orders | View order history, cancel eligible orders, and review delivered orders |
| Table bookings | Create and cancel bookings; select a booking for dine-in checkout |
| Admin dashboard | View orders and reports, update order status, and manage menu availability |

## Technology

- **Application:** PHP
- **Database:** MySQL or MariaDB, accessed with PHP `mysqli`
- **Local environment:** XAMPP (Apache and MySQL)
- **Interface:** HTML and CSS

## Project structure

```text
.
├── admin/
│   └── index.php     # Admin dashboard
├── database/
│   └── food_ordering.sql # Food-ordering database structure
├── bookings.php      # Table booking and booking history
├── cart.php          # Cart and checkout
├── common.php        # Shared layout, session, and helper functions
├── db.php            # MySQL connection
├── index.php         # Restaurant and menu browsing
├── login.php         # Customer login
├── otp.php           # OTP verification
├── orders.php        # Order history and reviews
├── register.php      # Customer registration
└── style.css         # Application styles
```

## Run locally

### Requirements

- PHP with the `mysqli` extension
- MySQL or MariaDB
- A local PHP web server, such as XAMPP

### Setup

1. Clone or copy this repository into your web server's document root (for XAMPP, usually `htdocs`).
2. Start Apache and MySQL.
3. Create a MySQL database named `food_ordering`.
4. Import [`database/food_ordering.sql`](./database/food_ordering.sql) using phpMyAdmin's **Import** tab.
5. Review `db.php` and configure the connection for your local MySQL account.
6. Open `http://localhost/restaurant/` in your browser. Change `restaurant` in the URL if you chose another folder name.

### Database requirement

The SQL file contains only the `food_ordering` database structure (tables, triggers, and views). It excludes rows and other databases from the phpMyAdmin server export. No sample restaurant or menu data is included, so add appropriate data before using the app.

### Entity relationship diagram

The project ER diagram is shown below. The full table and foreign-key relationships from [`database/food_ordering.sql`](./database/food_ordering.sql) are also documented in the Mermaid diagram that follows.

![Restaurant food ordering ER diagram](./assets/ER_diagram.png)

The Mermaid diagram below includes the schema's foreign-key relationships. `stock_movements.order_id` is not shown as a relationship because the SQL schema does not define a foreign key for it.

```mermaid
erDiagram
    ADDRESSES {
        int address_id PK
        int customer_id FK
    }
    CART_ITEMS {
        int customer_id PK, FK
        int item_id PK, FK
        int quantity
    }
    CATEGORIES {
        int category_id PK
        int restaurant_id FK
        string name
    }
    COUPONS {
        int coupon_id PK
        int restaurant_id FK
        string code
    }
    CUSTOMERS {
        int customer_id PK
        string full_name
        string email
    }
    DELIVERY_PARTNERS {
        int partner_id PK
        string full_name
    }
    DINING_TABLES {
        int table_id PK
        int restaurant_id FK
        string table_number
    }
    INGREDIENTS {
        int ingredient_id PK
        int restaurant_id FK
        string name
    }
    MENU_ITEMS {
        int item_id PK
        int category_id FK
        string name
    }
    MENU_ITEM_INGREDIENTS {
        int item_id PK, FK
        int ingredient_id PK, FK
        decimal qty_required
    }
    ORDERS {
        int order_id PK
        int customer_id FK
        int restaurant_id FK
        int address_id FK
        int partner_id FK
        int booking_id FK
        int coupon_id FK
    }
    ORDER_ITEMS {
        int order_item_id PK
        int order_id FK
        int item_id FK
        int quantity
    }
    ORDER_STATUS_HISTORY {
        int history_id PK
        int order_id FK
    }
    PAYMENTS {
        int payment_id PK
        int order_id FK
        string status
    }
    RESTAURANTS {
        int restaurant_id PK
        string name
    }
    REVIEWS {
        int review_id PK
        int order_id FK
        int customer_id FK
        int restaurant_id FK
    }
    STOCK_MOVEMENTS {
        int movement_id PK
        int ingredient_id FK
        int order_id
    }
    TABLE_BOOKINGS {
        int booking_id PK
        int customer_id FK
        int table_id FK
    }

    CUSTOMERS ||--o{ ADDRESSES : has
    CUSTOMERS ||--o{ CART_ITEMS : owns
    MENU_ITEMS ||--o{ CART_ITEMS : added_to
    RESTAURANTS ||--o{ CATEGORIES : offers
    RESTAURANTS ||--o{ COUPONS : provides
    RESTAURANTS ||--o{ DINING_TABLES : has
    RESTAURANTS ||--o{ INGREDIENTS : stocks
    CATEGORIES ||--o{ MENU_ITEMS : contains
    MENU_ITEMS ||--o{ MENU_ITEM_INGREDIENTS : uses
    INGREDIENTS ||--o{ MENU_ITEM_INGREDIENTS : included_in
    CUSTOMERS ||--o{ ORDERS : places
    RESTAURANTS ||--o{ ORDERS : receives
    ADDRESSES o|--o{ ORDERS : delivery_address
    DELIVERY_PARTNERS o|--o{ ORDERS : delivers
    TABLE_BOOKINGS o|--o{ ORDERS : linked_to
    COUPONS o|--o{ ORDERS : applied_to
    ORDERS ||--o{ ORDER_ITEMS : contains
    MENU_ITEMS ||--o{ ORDER_ITEMS : ordered_as
    ORDERS ||--o{ ORDER_STATUS_HISTORY : tracks
    ORDERS ||--o| PAYMENTS : paid_by
    ORDERS ||--o| REVIEWS : reviewed_in
    CUSTOMERS ||--o{ REVIEWS : writes
    RESTAURANTS ||--o{ REVIEWS : receives
    INGREDIENTS ||--o{ STOCK_MOVEMENTS : records
    CUSTOMERS ||--o{ TABLE_BOOKINGS : makes
    DINING_TABLES ||--o{ TABLE_BOOKINGS : reserved_for
```

> **Stored procedures:** The export does not include stored procedures. Several app actions call procedures such as `sp_add_to_cart`, `sp_place_order`, and `sp_book_table`; those actions need the matching procedures added to the database before they will work. The downloaded server-wide export is not included; it contained unrelated databases and phpMyAdmin tables.

## Development and security notes

- OTP display is enabled for local demo use. Do not use demo OTP behavior in a production deployment.
- The admin page currently contains a hard-coded password. Replace it with a secure configuration before running the application, and never reuse a real account password.
- The default database connection in `db.php` uses local development settings. Do not deploy with insecure or default database credentials.
- This project has not been documented as production-ready. Before deployment, review authentication, authorization, validation, error handling, email delivery, and HTTPS configuration.
- Never commit real passwords, API keys, private keys, or customer data.

## Contributing

Bug reports and focused improvements are welcome. Please open an [issue](https://github.com/chin17-Abd/restaurant-food-ordering/issues) to discuss a significant change before submitting it.

## License

No license has been added to this repository yet. Until a license is provided, reuse and redistribution are not granted by the project.
