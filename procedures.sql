--funkcja zwracajaca koszt wszystkich uslug dodatkowych:
create or replace function ad_serv_price(g_id integer)
    return number
as
    v_ad_serv additional_services.price%type;
begin

    select sum(ads.price)
    into v_ad_serv
    from additional_services_orders adso
             left join additional_services ads on (adso.service_id = ads.as_id)
    where adso.guest_id = g_id;

    if v_ad_serv is not null then
        return v_ad_serv;
    else
        return 0;
    end if;
end;
/

--funkcja zwracajaca ostateczny koszt zakwaterowania i obslugi dla danego goscia:
create or replace function get_total_price(reserv_id integer)
    return number
as
    v_guest_id         reservations.guest_id%type;
    v_check_in_date    reservations.check_in%type;
    v_check_out_date   reservations.check_out%type;
    v_discount_percent reservations.discount_percent%type;
    v_price            reservations.total_price%type;
    v_price_p_n        rooms.price_per_night%type;
    v_price_ad_s       additional_services.price%type;
    v_days             int;
begin

    select guest_id, check_in, check_out, discount_percent
    into v_guest_id, v_check_in_date, v_check_out_date, v_discount_percent
    from reservations
    where reservation_id = reserv_id;

    select to_date(v_check_out_date, 'dd.mm.yy') - to_date(v_check_in_date, 'dd.mm.yy') into v_days from dual;

    select r.price_per_night
    into v_price_p_n
    from room_reservation rr
             left join rooms r using (room_number)
    where rr.reservation_id = reserv_id;

    v_price := v_days * v_price_p_n;
    v_price_ad_s := ad_serv_price(v_guest_id);

    if v_discount_percent is not null then
        return v_price * (100 - v_discount_percent) / 100 + v_price_ad_s;
    else
        return v_price + v_price_ad_s;
    end if;
end;
/

create or replace trigger additional_services_cost_trigger
    after insert
    on additional_services_orders
    for each row
declare
    cursor reservation_ids is select RESERVATION_ID
                              from RESERVATIONS
                              where RESERVATIONS.GUEST_ID = :new.GUEST_ID;
begin
    open reservation_ids;
    for curr_id in reservation_ids
        loop
            update_reservation_total_cost(curr_id.RESERVATION_ID);
        end loop;
    close reservation_ids;
end;

--wyzwalacz, ktory po dodaniu albo zmianie rezerwacji updatuje koszt rezerwacji
create or replace trigger reservation_cost_monitor
    after insert or update
    on reservations
    for each row
begin
    if inserting then
        update_reservation_total_cost(:new.RESERVATION_ID);
    end if;
    if updating then
        if :old.check_out != :new.check_out then
            update_reservation_total_cost(:old.RESERVATION_ID);
        end if;
    end if;
end;
/
create or replace procedure update_reservation_total_cost(reserv_id int) as
begin
    update_disc(reserv_id);
    update reservations set total_price = get_total_price(reserv_id) where reservation_id = reserv_id;
end;

--procedura, ktora zmienia stanowisko pracownika:
create or replace procedure update_pos(p_eid integer, p_pid integer)
as
    v_min_salary positions.min_salary%type;
    v_max_salary positions.max_salary%type;
    v_new_salary positions.max_salary%type;
    v_pos_name   positions.name%type;
    v_name       employees.first_name%type;
    v_surname    employees.last_name%type;
begin
    select min_salary, max_salary, name
    into v_min_salary, v_max_salary, v_pos_name
    from positions
    where position_id = p_pid;
    select first_name, last_name into v_name, v_surname from employees where employee_id = p_eid;
    v_new_salary := (v_min_salary + v_max_salary) / 2;
    update employees set position_id = p_pid where employee_id = p_eid;
    dbms_output.put_line('Zmieniono stanowisko pracownika ' || v_name || ' ' || v_surname || ' na ' || v_pos_name);
    update payroll set salary = v_new_salary where employee_id = p_eid;
    dbms_output.put_line('Zmieniono wyplate dla pracownika ' || v_name || ' ' || v_surname || ' na ' || v_new_salary);
end;
/

-- wyzwalacz, ktory monitoruje czy placa pracownika miesci sie w zakresie przewidzianym przez stanowisko:
create or replace trigger payroll_salary_checker
    before update
    on payroll
    for each row
declare
    v_max_salary positions.max_salary%type;
    v_min_salary positions.min_salary%type;
begin
    if :old.salary != :new.salary then
        select min_salary, max_salary
        into v_min_salary,v_max_salary
        from positions p
                 join employees e on p.position_id = e.position_id
        where employee_id = :old.employee_id;
        if :new.salary > v_max_salary or :new.salary < v_min_salary then
            raise_application_error(-1,
                                    'Nie mozna zmieniac pensji pracownika na niezgodna z zakresem przewidzianym na stanowisku.');
        end if;
    end if;
end;

--procedura, ktora aktualizuje znizke w zaleznosci od ilosci uslug dodatkowych:
create or replace procedure update_disc(reserv_id integer)
as
    v_guest_id         reservations.guest_id%type;
    v_discount_percent reservations.discount_percent%type;
    v_new_disc         reservations.discount_percent%type := 25;
    v_numb_of_ad_serv  integer;
begin
    select guest_id, discount_percent
    into v_guest_id, v_discount_percent
    from reservations
    where reservation_id = reserv_id;
    select count(service_id)
    into v_numb_of_ad_serv
    from additional_services_orders
    where guest_id = v_guest_id;

    if v_numb_of_ad_serv >= 3 and v_discount_percent < v_new_disc then
        update reservations set discount_percent = v_new_disc where reservation_id = reserv_id;
        dbms_output.put_line('Zmieniono znizke dla rezerwacji o numerze ' || reserv_id || ' na ' || v_new_disc);
    end if;
end;
/

--wyzwalacz, ktory po usunieciu albo dodaniu rezerwacji zmienia status pokoju na wolny/zajety odpowiednio:
create or replace trigger update_room_availability
    after insert or delete
    on room_reservation
    for each row
begin
    if inserting then
        update rooms set room_availability = 'unavailable' where room_number = :new.room_number;
        dbms_output.put_line('Zmieniono status pokoju na niedostepny');
    elsif deleting then
        update rooms set room_availability = 'available' where room_number = :old.room_number;
        dbms_output.put_line('Zmieniono status pokoju na dostepny');
    end if;
end;
/