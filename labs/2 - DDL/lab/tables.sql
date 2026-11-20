drop table if exists loans;
drop table if exists books;
drop table if exists readers;
drop table if exists authors;
 
drop type if exists loan_status;
drop type if exists reader_status;
drop type if exists book_status;

create type loan_status as enum ('issued', 'returned', 'overdue');
create type reader_status as enum ('active', 'inactive');
create type book_status as enum ('available', 'unavailable');


create table if not exists authors (
    author_id integer generated always as identity primary key,
    first_name varchar(32) not null,
    last_name varchar(32) not null,
    middle_name varchar(32)
);

create table if not exists readers (
    reader_id integer generated always as identity primary key,
    first_name varchar(32) not null,
    last_name varchar(32) not null,
    middle_name varchar(32) not null,
    phone varchar(32) not null unique,
    email varchar(64) not null unique,
    registration_date date not null default current_date,
    reader_status reader_status not null default 'active'
);

create table if not exists books (
    book_id integer generated always as identity primary key,
    author_id integer not null references authors(author_id),
    title varchar(256) not null,
    genre varchar(32),
    publication_year smallint,
    pages integer not null check(pages > 0),
    language varchar(32),
    book_status book_status not null default 'available'
);

create table if not exists loans (
    loan_id integer generated always as identity primary key,
    reader_id integer not null references readers(reader_id),
    book_id integer not null references books(book_id),
    loan_status loan_status not null default 'issued',
    loan_date date not null default current_date,
    due_date date not null check(due_date >= loan_date),
    return_date date check(return_date is null or return_date >= loan_date)
);


insert into authors (first_name, last_name, middle_name) values
    ('Тарас', 'Шевченко', 'Григорович'),
    ('Іван', 'Франко', 'Якович'),
    ('Григорій', 'Сковорода', 'Савич'),
    ('Володимир ', 'Сосюра', 'Миколайович'),
    ('William ', 'Shakespeare', null),
    ('Agatha', 'Christie', null),
    ('William', 'Yeats', 'Butler');


insert into readers (first_name, last_name, middle_name, phone, email, registration_date, reader_status) values
    ('Олена',  'Коваленко',  'Петрівна',     '+380501112233', 'olena.kovalenko@example.com', '2026-01-15', 'active'),
    ('Андрій', 'Мельник',    'Іванович',     '+380672223344', 'andrii.melnyk@example.com',   '2026-02-03', 'active'),
    ('Марія',  'Шевчук',     'Олександрівна','+380933334455', 'maria.shevchuk@example.com',  '2026-03-21', 'active'),
    ('Ігор',   'Бондаренко', 'Сергійович',   '+380504445566', 'ihor.bondarenko@example.com', '2025-11-10', 'inactive'),
    ('Софія',  'Ткаченко',   'Андріївна',    '+380675556677', 'sofia.tkachenko@example.com', '2026-09-01', 'active');


insert into books (author_id, title, genre, publication_year, pages, language, book_status) values
    (1, 'Кобзар',                      'Поезія',          1840, 320, 'Українська', 'available'),
    (2, 'Захар Беркут',                'Історична повість',1883, 224, 'Українська', 'available'),
    (3, 'Сад божественних пісень',     'Поезія',          null, 180, 'Українська', 'unavailable'),
    (4, 'Любіть Україну',              'Поезія',          1944,  96, 'Українська', 'available'),
    (5, 'Hamlet',                      'Драма',           1603, 160, 'English',    'unavailable'),
    (6, 'Murder on the Orient Express','Детектив',        1934, 256, 'English',    'unavailable'),
    (7, 'The Tower',                   'Поезія',          1928,  96, 'English',    'available'),
    (2, 'Лис Микита',                  'Казка',           1890, 128, 'Українська', 'available');
 

insert into loans (reader_id, book_id, loan_status, loan_date, due_date, return_date) values
    (1, 1, 'returned', '2026-10-20', '2026-11-03', '2026-11-01'),
    (1, 5, 'overdue',  '2026-11-05', '2026-11-19', null),
    (2, 2, 'returned', '2026-11-01', '2026-11-15', '2026-11-10'),
    (3, 6, 'issued',   '2026-11-10', '2026-11-24', null),
    (2, 3, 'issued',   '2026-11-15', '2026-11-29', null),
    (4, 7, 'returned', '2026-06-01', '2026-06-15', '2026-06-12');