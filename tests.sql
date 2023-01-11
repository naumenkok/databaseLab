--Testowanie funkcji zwracajacej koszt wszystkich uslug dodatkowych:
SELECT ad_serv_price(101) FROM dual;
SELECT ad_serv_price(103) FROM dual;

--Testowanie funkcji zwracajacej zwracajacej ostateczny koszt zakwaterowania i obslugi dla danego goscia:
SELECT get_total_price(101) FROM dual;
SELECT get_total_price(102) FROM dual;
SELECT get_total_price(103) FROM dual;

--Testowanie procedury, która zmienia stanowisko pracownika:
SELECT e.employee_id, e.position_id, p.salary FROM employees e LEFT JOIN payroll p ON(e.employee_id=p.employee_id);
DECLARE
v_position_id_f employees.employee_id%TYPE;
v_position_id_s employees.position_id%TYPE;
BEGIN
 SELECT position_id INTO v_position_id_f FROM employees WHERE employee_id = 101;
 SELECT position_id INTO v_position_id_s FROM employees WHERE employee_id = 102;
 update_pos(101, v_position_id_s); 
 update_pos(102, v_position_id_f); 
END; 
/
SELECT e.employee_id, e.position_id, p.salary FROM employees e LEFT JOIN payroll p ON(e.employee_id=p.employee_id);

--Testowanie procedury, która zmienia znizke w zaleznosci od ilosci uslug dodatkowych:
SELECT reservation_id, discount_percent FROM reservations;
DECLARE
v_guest_id INTEGER := 101;
v_reservation_id INTEGER;
BEGIN
    INSERT INTO additional_services_orders (aso_id, guest_id, service_id, order_date)
        VALUES (104, v_guest_id, 101, TO_DATE('2022-01-03', 'yyyy/mm/dd'));
    SELECT reservation_id INTO v_reservation_id FROM reservations WHERE guest_id = v_guest_id;
    update_disc(v_reservation_id);
END; 
/
SELECT reservation_id, discount_percent FROM reservations;


