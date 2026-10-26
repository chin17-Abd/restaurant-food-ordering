# Restaurant Food Ordering

A PHP and MySQL restaurant ordering app with customer accounts, menu browsing, cart and checkout, order history, table bookings, and an admin dashboard for orders, menu items, bookings, and reports.

## Requirements

- PHP with the `mysqli` extension
- MySQL or MariaDB
- A local web server such as XAMPP

## Run locally with XAMPP

1. Copy or clone this project into XAMPP's `htdocs` folder.
2. Start **Apache** and **MySQL** from the XAMPP Control Panel.
3. Create a MySQL database named `food_ordering`.
4. Import the project's database schema and sample data into that database.
5. Check the connection settings in `db.php`. The defaults are MySQL on `localhost`, user `root`, and a blank password; update them if your local MySQL uses different credentials.
6. Open `http://localhost/restaurant/` in your browser (adjust the URL if you used a different folder name).

> **Database setup note:** This repository currently does not include the SQL schema or sample data. The application expects tables, views, and stored procedures for its restaurant, menu, customer, cart, order, booking, and reporting features. You will need the matching SQL setup script before the app can run.

## Features

- Customer registration, login, and OTP verification (demo mode)
- Restaurant menus and cart
- Food orders and order tracking
- Table bookings
- Admin pages for order management, menu updates, bookings, and reports

## Security

This project is intended for local learning and development. Before deploying it publicly, replace demo credentials and settings, configure secure database credentials, turn off demo OTP display, and use HTTPS. Never commit real passwords, API keys, or customer data.
