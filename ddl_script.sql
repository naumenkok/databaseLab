create table rooms
(
    room_number       number(3) primary key,
    room_type_id      integer      not null references room_types (room_type_id),
    number_of_beds    number(1)    not null,
    price_per_night   number(5, 2) not null,
    room_availability varchar2(10) not null
);
create table room_types
(
    room_type_id   integer primary key,
    room_type_name varchar2(30)
);
create table guests
(
    guest_id     integer primary key,
    first_name   varchar2(20) not null,
    last_name    varchar2(20) not null,
    address      varchar2(30) not null,
    phone_number varchar2(15) not null
);
create table reservations
(
    reservation_id   int primary key,
    guest_id         int references guests (guest_id),
    check_in         date not null,
    check_out        date not null,
    discount_percent int,
    total_price      number(10, 2)
);
create table room_reservation
(
    id             int primary key,
    reservation_id int references reservations (reservation_id),
    room_number    number(3) references rooms (room_number)
);
create table amenities
(
    amenity_id   integer primary key,
    amenity_name varchar(50) not null
);
create table room_amenity
(
    id          integer primary key,
    room_number integer not null,
    amenity_id  integer not null,
    foreign key (room_number) references rooms (room_number),
    foreign key (amenity_id) references amenities (amenity_id)
);
create table employees
(
    employee_id integer primary key,
    first_name  varchar2(20) not null,
    last_name   varchar2(20) not null,
    job_title   varchar2(30) not null,
    email       varchar2(30) not null,
    phone       varchar2(15) not null
);
create table payroll
(
    employee_id integer primary key,
    salary      number(10, 2) not null,
    foreign key (employee_id) references employees (employee_id)
);