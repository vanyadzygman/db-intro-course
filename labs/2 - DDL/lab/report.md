# Лабораторна робота №2. Перетворення ER-діаграми на схему PostgreSQL

## Мета

Перетворити концептуальну ER-модель бібліотеки з лабораторної роботи №1 на реляційну схему в PostgreSQL: створити таблиці з первинними та зовнішніми ключами, налаштувати обмеження та заповнити таблиці тестовими даними.

## Завдання

- написати SQL DDL-інструкції для кожної таблиці з ER-діаграми;
- визначити типи даних, первинні та зовнішні ключі, обмеження `UNIQUE`, `NOT NULL`, `CHECK`, `DEFAULT`;
- вставити тестові дані (не менше 3–5 рядків у кожну таблицю);
- перевірити роботу схеми в pgAdmin.

SQL-скрипт з усіма операторами `CREATE TABLE` та `INSERT` знаходиться у файлі [`tables.sql`](tables.sql).

---

## 1. Перетворення ER-моделі на таблиці

Правила перетворення:

- кожна сутність стає таблицею (назви таблиць у множині, в нижньому регістрі);
- кожен зв'язок one-to-many реалізується стовпцем зовнішнього ключа в таблиці на стороні «багато»;
- зв'язок many-to-many між читачами та книгами реалізовано таблицею `loans`, яка має власний первинний ключ `loan_id` і два зовнішні ключі;
- статуси читача, книги та видачі реалізовано типами `ENUM`.

| Сутність (ER) | Таблиця (PostgreSQL) |
| ------------- | -------------------- |
| Author        | `authors`            |
| Reader        | `readers`            |
| Book          | `books`              |
| Loan          | `loans`              |

Порядок створення таблиць: спочатку батьківські (`authors`, `readers`), потім дочірні (`books`, `loans`), щоб зовнішні ключі посилалися на вже існуючі таблиці.

---

## 2. Типи ENUM

| Тип             | Допустимі значення              | Використовується в      |
| --------------- | ------------------------------- | ----------------------- |
| `reader_status` | `active`, `inactive`            | `readers.reader_status` |
| `book_status`   | `available`, `unavailable`      | `books.book_status`     |
| `loan_status`   | `issued`, `returned`, `overdue` | `loans.loan_status`     |

---

## 3. Опис таблиць

Для первинних ключів використано `INTEGER GENERATED ALWAYS AS IDENTITY`: значення генерує сама база, починаючи з 1.

### Таблиця `authors`

| Стовпець    | Тип                | Ключ / обмеження |
| ----------- | ------------------ | ---------------- |
| author_id   | INTEGER (IDENTITY) | PRIMARY KEY      |
| first_name  | VARCHAR(32)        | NOT NULL         |
| last_name   | VARCHAR(32)        | NOT NULL         |
| middle_name | VARCHAR(32)        | необов'язковий   |

### Таблиця `readers`

| Стовпець          | Тип                | Ключ / обмеження               |
| ----------------- | ------------------ | ------------------------------ |
| reader_id         | INTEGER (IDENTITY) | PRIMARY KEY                    |
| first_name        | VARCHAR(32)        | NOT NULL                       |
| last_name         | VARCHAR(32)        | NOT NULL                       |
| middle_name       | VARCHAR(32)        | NOT NULL                       |
| phone             | VARCHAR(32)        | NOT NULL, UNIQUE               |
| email             | VARCHAR(64)        | NOT NULL, UNIQUE               |
| registration_date | DATE               | NOT NULL, DEFAULT CURRENT_DATE |
| reader_status     | reader_status      | NOT NULL, DEFAULT 'active'     |

### Таблиця `books`

| Стовпець         | Тип                | Ключ / обмеження                           |
| ---------------- | ------------------ | ------------------------------------------ |
| book_id          | INTEGER (IDENTITY) | PRIMARY KEY                                |
| author_id        | INTEGER            | NOT NULL, FOREIGN KEY → authors(author_id) |
| title            | VARCHAR(256)       | NOT NULL                                   |
| genre            | VARCHAR(32)        | необов'язковий                             |
| publication_year | SMALLINT           | необов'язковий                             |
| pages            | INTEGER            | NOT NULL, CHECK (pages > 0)                |
| language         | VARCHAR(32)        | необов'язковий                             |
| book_status      | book_status        | NOT NULL, DEFAULT 'available'              |

### Таблиця `loans`

| Стовпець    | Тип                | Ключ / обмеження                                            |
| ----------- | ------------------ | ----------------------------------------------------------- |
| loan_id     | INTEGER (IDENTITY) | PRIMARY KEY                                                 |
| reader_id   | INTEGER            | NOT NULL, FOREIGN KEY → readers(reader_id)                  |
| book_id     | INTEGER            | NOT NULL, FOREIGN KEY → books(book_id)                      |
| loan_status | loan_status        | NOT NULL, DEFAULT 'issued'                                  |
| loan_date   | DATE               | NOT NULL, DEFAULT CURRENT_DATE                              |
| due_date    | DATE               | NOT NULL, CHECK (due_date ≥ loan_date)                      |
| return_date | DATE               | необов'язковий, CHECK (return_date порожня або ≥ loan_date) |

---

## 4. Зв'язки (зовнішні ключі)

| Зовнішній ключ  | Посилається на    | Тип зв'язку |
| --------------- | ----------------- | ----------- |
| books.author_id | authors.author_id | one-to-many |
| loans.reader_id | readers.reader_id | one-to-many |
| loans.book_id   | books.book_id     | one-to-many |

Поведінка при видаленні для зовнішніх ключів не змінювалась, тому діє стандартна (`NO ACTION`): не можна видалити автора, читача чи книгу, якщо на них посилаються записи в дочірніх таблицях. Так зберігається історія видач і каталог.

---

## 5. Обмеження

- **PRIMARY KEY:** у кожній таблиці один первинний ключ.
- **FOREIGN KEY:** `books.author_id`, `loans.reader_id`, `loans.book_id`.
- **UNIQUE:** `readers.phone`, `readers.email`.
- **NOT NULL:** усі обов'язкові поля, визначені в лабораторній роботі №1.
- **CHECK:** `pages > 0`, `due_date >= loan_date`, `return_date >= loan_date`, якщо заповнена.
- **ENUM:** `reader_status`, `book_status`, `loan_status` приймають лише наведені вище значення.
- **DEFAULT:** `registration_date` та `loan_date` дорівнюють поточній даті; `reader_status = 'active'`, `book_status = 'available'`, `loan_status = 'issued'`.

---

## 6. Припущення

- Кожна книга має одного автора.
- Кожен запис у таблиці `books` відповідає одній фізичній книзі, кількість примірників окремо не обліковується.
- Жанр і мова зберігаються як текст і не винесені в окремі таблиці.
- Поле `return_date` порожнє, доки книга на руках.
- Статус `overdue` самостійно не оновлюється: його виставляє запит чи тригер, коли `due_date` минула, а книгу не повернуто.
- Бізнес-правила, які потребують підрахунку інших рядків або перевірки значень в інших таблицях (не більше 5 книг на читача, неможливість видати недоступну книгу чи книгу неактивному читачу, строк 14 днів), у схемі не реалізовано. Їх буде перевірено в наступних лабораторних роботах.

---

## 7. Тестові дані

У кожну таблицю вставлено щонайменше 5 рядків. Спочатку заповнюються батьківські таблиці (`authors`, `readers`), потім `books`, потім `loans`, щоб зовнішні ключі посилалися на вже існуючі записи.

| Таблиця | Кількість рядків |
| ------- | ---------------- |
| authors | 7                |
| readers | 5                |
| books   | 8                |
| loans   | 6                |

Особливості даних:

- один читач має статус `inactive`, одна читачка не має жодної видачі;
- серед видач є всі три статуси: `issued`, `returned`, `overdue`;
- книги, які зараз на руках, мають статус `unavailable`, а їхні видачі мають порожню `return_date`;
- у автора Івана Франка дві книги, у одного з авторів по батькові немає (`NULL`), в одній книзі не вказано рік видання.

---

## 8. Перевірка в pgAdmin

Скрипт `tables.sql` виконано в pgAdmin без помилок.

---

## 9. Висновок

У ході лабораторної роботи №2 ER-модель бібліотеки перетворено на реляційну схему PostgreSQL з чотирьох таблиць: `authors`, `readers`, `books`, `loans`. Для кожної таблиці визначено типи даних, первинні ключі та обмеження `NOT NULL`, `UNIQUE`, `CHECK`, `DEFAULT`, а статуси задано типами `ENUM`. Зв'язки між сутностями реалізовано зовнішніми ключами, а зв'язок many-to-many між читачами та книгами реалізовано таблицею `loans`.

Таблиці заповнено тестовими даними, узгодженими зі схемою, та перевірено запитами `SELECT`, зокрема запитом з'єднання кількох таблиць. Отримана схема є основою для лабораторних робіт з SQL-запитами, нормалізацією та міграціями.
