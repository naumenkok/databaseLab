--Funkcja zwracajaca koszt wszystkich uslug dodatkowych:
CREATE FUNCTION ad_serv_price(g_id INTEGER)
RETURN NUMBER
AS
    v_ad_serv additional_services.price%TYPE;
BEGIN
    
    SELECT SUM(ads.price) INTO v_ad_serv
        FROM additional_services_orders adso LEFT JOIN additional_services ads ON(adso.service_id=ads.as_id) WHERE adso.guest_id=g_id;
    
    IF v_ad_serv IS NOT NULL THEN
        RETURN v_ad_serv;
    ELSE
        RETURN 0;
    END IF;
END;
/

--Funkcja zwracajaca ostateczny koszt zakwaterowania i obslugi dla danego goscia:
CREATE FUNCTION get_total_price (reserv_id INTEGER)
RETURN NUMBER
AS
    v_guest_id reservations.guest_id%TYPE;
    v_check_in_date reservations.check_in%TYPE;
    v_check_out_date reservations.check_out%TYPE;
    v_discount_percent reservations.discount_percent%TYPE;
    v_price reservations.total_price%TYPE;
    v_price_p_n rooms.price_per_night%TYPE;
    v_price_ad_s rooms.price_per_night%TYPE;
    v_days INT;
BEGIN
    
    SELECT guest_id, check_in, check_out, discount_percent INTO v_guest_id, v_check_in_date, v_check_out_date, v_discount_percent
        FROM reservations WHERE reservation_id = reserv_id;
    
    SELECT to_date(v_check_out_date, 'dd.mm.yy')-to_date(v_check_in_date, 'dd.mm.yy') INTO v_days from dual;
    
    SELECT r.price_per_night INTO v_price_p_n
        FROM room_reservation rr LEFT JOIN rooms r USING(room_number) WHERE rr.reservation_id=reserv_id;
    
    v_price:=v_days*v_price_p_n;
    v_price_ad_s:=ad_serv_price(v_guest_id);
    
    IF v_discount_percent IS NOT NULL THEN
        RETURN v_price*(100-v_discount_percent)/100+v_price_ad_s;
    ELSE
        RETURN v_price+v_price_ad_s;
    END IF;
END;
/

--Procedura, która zmienia stanowisko pracownika:
CREATE PROCEDURE update_pos (p_eid INTEGER, p_pid INTEGER)
AS
v_min_salary positions.min_salary%TYPE;
v_max_salary positions.max_salary%TYPE;
v_new_salary positions.max_salary%TYPE;
v_pos_name positions.name%TYPE;
v_name employees.first_name%TYPE;
v_surname employees.last_name%TYPE;
BEGIN
    SELECT min_salary, max_salary, name INTO v_min_salary, v_max_salary, v_pos_name FROM positions WHERE position_id = p_pid;
    SELECT first_name, last_name INTO v_name, v_surname FROM employees WHERE employee_id = p_eid;
    v_new_salary := (v_min_salary+v_max_salary)/2;
    UPDATE employees SET position_id = p_pid WHERE employee_id = p_eid;
    dbms_output.put_line ('Zmieniono stanowisko pracownika '|| v_name|| ' '|| v_surname || ' na ' || v_pos_name);
    UPDATE payroll SET salary = v_new_salary WHERE employee_id = p_eid;
    dbms_output.put_line ('Zmieniono wyp³atê dla pracownika '|| v_name|| ' '|| v_surname || ' na ' || v_new_salary);
END;
/

--Procedura, która zmienia znizke w zaleznosci od ilosci uslug dodatkowych:
CREATE PROCEDURE update_disc (reserv_id INTEGER)
AS
    v_guest_id reservations.guest_id%TYPE;
    v_discount_percent reservations.discount_percent%TYPE;
    v_new_disc reservations.discount_percent%TYPE := 25;
    v_numb_of_ad_serv INTEGER;
BEGIN
    SELECT guest_id, discount_percent INTO v_guest_id, v_discount_percent FROM reservations WHERE reservation_id = reserv_id;
    SELECT count(service_id) INTO v_numb_of_ad_serv
        FROM additional_services_orders WHERE guest_id=v_guest_id;
    
    IF v_numb_of_ad_serv >= 3 AND v_discount_percent < v_new_disc THEN
        UPDATE reservations SET discount_percent = v_new_disc WHERE reservation_id = reserv_id;
        dbms_output.put_line ('Zmieniono znizke dla rezerwacji o numerze '|| reserv_id || ' na '|| v_new_disc);
    END IF;
END;
/

