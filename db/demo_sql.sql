-- Drop tables if they exist
DROP TABLE IF EXISTS deliveries;
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS customers;

-- Customers
CREATE TABLE customers (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    phone TEXT
);

INSERT INTO customers (name, email, phone) VALUES
('Alice Johnson', 'alice@example.com', '555-1234'),
('Bob Smith', 'bob@example.com', '555-2345'),
('Charlie Brown', 'charlie@example.com', '555-3456'),
('Dana Lee', 'dana@example.com', '555-4567'),
('Ethan White', 'ethan@example.com', '555-5678'),
('Fiona Adams', 'fiona@example.com', '555-6789');

-- Products
CREATE TABLE products (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    price DECIMAL(10,2) NOT NULL
);

INSERT INTO products (name, price) VALUES
('Wireless Mouse', 29.99),
('Mechanical Keyboard', 89.99),
('USB-C Hub', 49.99),
('Laptop Stand', 39.99),
('Noise-Canceling Headphones', 129.99),
('Webcam 1080p', 59.99),
('Bluetooth Speaker', 79.99),
('Portable SSD 1TB', 119.99);

-- Orders
CREATE TABLE orders (
    id INTEGER PRIMARY KEY,
    customer_id INTEGER NOT NULL,
    order_date TEXT NOT NULL,
    status TEXT NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES customers(id)
);

INSERT INTO orders (customer_id, order_date, status) VALUES
(1, '2025-05-01', 'shipped'),
(2, '2025-05-03', 'processing'),
(3, '2025-05-04', 'delivered'),
(1, '2025-05-07', 'cancelled'),
(4, '2025-05-02', 'shipped'),
(5, '2025-05-05', 'processing'),
(6, '2025-05-06', 'delivered'),
(2, '2025-05-06', 'processing'),
(3, '2025-05-07', 'shipped'),
(5, '2025-05-08', 'delivered');

-- Order Items
CREATE TABLE order_items (
    id INTEGER PRIMARY KEY,
    order_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    quantity INTEGER NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(id),
    FOREIGN KEY (product_id) REFERENCES products(id)
);

INSERT INTO order_items (order_id, product_id, quantity) VALUES
(1, 1, 1),
(1, 2, 1),
(2, 3, 2),
(3, 5, 1),
(3, 4, 1),
(4, 2, 1),
(5, 6, 1),
(5, 7, 1),
(6, 8, 1),
(6, 1, 2),
(7, 5, 1),
(7, 2, 1),
(8, 3, 1),
(8, 6, 1),
(9, 4, 2),
(9, 7, 1),
(10, 8, 1),
(10, 1, 1),
(10, 5, 1),
(10, 2, 1);

-- Deliveries
CREATE TABLE deliveries (
    id INTEGER PRIMARY KEY,
    order_id INTEGER NOT NULL,
    delivery_date TEXT,
    carrier TEXT,
    tracking_number TEXT,
    status TEXT NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(id)
);

INSERT INTO deliveries (order_id, delivery_date, carrier, tracking_number, status) VALUES
(1, '2025-05-06', 'FedEx', 'FX12345678', 'shipped'),
(3, '2025-05-05', 'UPS', '1Z999AA10123456784', 'delivered'),
(5, '2025-05-06', 'DHL', 'DH45678901', 'shipped'),
(6, NULL, 'Canada Post', NULL, 'processing'),
(7, '2025-05-07', 'Purolator', 'PU123123123', 'delivered'),
(9, '2025-05-08', 'FedEx', 'FX98765432', 'shipped'),
(10, '2025-05-09', 'UPS', '1Z888AA10123456789', 'delivered');
