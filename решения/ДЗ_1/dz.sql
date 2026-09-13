-- ДЗ №1, вариант 2 «Служба доставки еды»
DROP SCHEMA IF EXISTS hw1 CASCADE;
CREATE SCHEMA hw1;
SET search_path = hw1;


-- Пользователи: клиенты сервиса
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(20) NOT NULL UNIQUE,   -- телефон работает как логин
    email VARCHAR(100),
    created_at TIMESTAMP NOT NULL DEFAULT now()
);


-- Рестораны: заведения, из которых возят еду
CREATE TABLE restaurants (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    district VARCHAR(50) NOT NULL,       -- по району ищем рестораны рядом
    address VARCHAR(200) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT true
);


-- Блюда: меню конкретного ресторана
CREATE TABLE dishes (
    id SERIAL PRIMARY KEY,
    restaurant_id INTEGER NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(8,2) NOT NULL CHECK (price > 0),
    is_available BOOLEAN NOT NULL DEFAULT true,
    UNIQUE (restaurant_id, name)         -- одинаковых названий в одном меню быть не должно
);


-- Курьеры
CREATE TABLE couriers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(20) NOT NULL UNIQUE,
    is_active BOOLEAN NOT NULL DEFAULT true
);


-- Заказы: кто, из какого ресторана, куда везём и в каком состоянии
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id),
    restaurant_id INTEGER NOT NULL REFERENCES restaurants(id),
    courier_id INTEGER REFERENCES couriers(id),   -- NULL, пока курьер не назначен
    delivery_address VARCHAR(200) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'created',
    created_at TIMESTAMP NOT NULL DEFAULT now(),
    delivered_at TIMESTAMP,

    CHECK (status IN ('created', 'cooking', 'delivering', 'delivered', 'cancelled')),
    CHECK (delivered_at IS NULL OR delivered_at >= created_at)
);


-- Позиции заказа: какие блюда и сколько штук.
-- Эта таблица разрешает связь многие ко многим между заказами и блюдами.
-- Составной ключ заодно не даёт добавить одно блюдо в заказ дважды.
CREATE TABLE order_items (
    order_id INTEGER NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    dish_id INTEGER NOT NULL REFERENCES dishes(id),
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    price DECIMAL(8,2) NOT NULL CHECK (price > 0),   -- цена на момент заказа

    PRIMARY KEY (order_id, dish_id)
);


-- Отзывы: оценка ресторана и отдельно оценка доставки
CREATE TABLE reviews (
    id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL UNIQUE REFERENCES orders(id) ON DELETE CASCADE,
    restaurant_rating INTEGER NOT NULL CHECK (restaurant_rating BETWEEN 1 AND 5),
    courier_rating INTEGER CHECK (courier_rating BETWEEN 1 AND 5),
    comment TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT now()
);


-- Индексы на внешние ключи. Для PRIMARY KEY и UNIQUE postgres делает их сам,
-- а FOREIGN KEY нет
-- order_items.order_id и reviews.order_id уже покрыты (составной PK и UNIQUE).
CREATE INDEX idx_dishes_restaurant ON dishes (restaurant_id);
CREATE INDEX idx_orders_user ON orders (user_id);
CREATE INDEX idx_orders_restaurant ON orders (restaurant_id);
CREATE INDEX idx_orders_courier ON orders (courier_id);
CREATE INDEX idx_order_items_dish ON order_items (dish_id);
CREATE INDEX idx_orders_created_at ON orders (created_at);
CREATE INDEX idx_restaurants_district ON restaurants (district);
