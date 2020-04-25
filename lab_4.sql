--Manager
create table "MANAGER" (
	"MANAGER_ID" NUMBER(10,0) NOT NULL,
	"FIRST_NAME" VARCHAR2(20 BYTE) NOT NULL,
	"LAST_NAME" VARCHAR2(20 BYTE) NOT NULL,
	PRIMARY KEY ("MANAGER_ID")
);

--Employee
create table "EMPLOYEE" (
	"EMPLOYEE_ID" NUMBER(10,0) NOT NULL,
	"MANAGER_ID" NUMBER(10,0) NOT NULL,
	"FIRST_NAME" VARCHAR2(20 BYTE) NOT NULL,
	"LAST_NAME" VARCHAR2(20 BYTE) NOT NULL,
	PRIMARY KEY ("EMPLOYEE_ID"),
	FOREIGN KEY ("MANAGER_ID") REFERENCES "MANAGER" ("MANAGER_ID")
);

--Sales
create table "SALES1" (
	"SALES_ID" NUMBER(10,0) NOT NULL,
	"EMPLOYEE_ID" NUMBER(10,0) NOT NULL,
	"CUSTOMER_ID" NUMBER(10,0) NOT NULL,
	"PRODUCT_ID" NUMBER(10,0) NOT NULL,
	"DATE_SOLD" DATE NOT NULL,
	PRIMARY KEY ("SALES_ID"),
	FOREIGN KEY ("EMPLOYEE_ID") REFERENCES "EMPLOYEE" ("EMPLOYEE_ID"),
	FOREIGN KEY ("CUSTOMER_ID") REFERENCES "CUSTOMER" ("CUSTOMER_ID"),
	FOREIGN KEY ("PRODUCT_ID") REFERENCES "PRODUCTS" ("PRODUCT_ID")
);

--Customer
create table "CUSTOMER" (
	"CUSTOMER_ID" NUMBER(10,0) NOT NULL,
	"FIRST_NAME" VARCHAR2(20 BYTE) NOT NULL,
	"LAST_NAME" VARCHAR2(20 BYTE) NOT NULL,
	"STREET_ADDRESS" VARCHAR2(50 BYTE) NOT NULL,
	"CITY" VARCHAR2(50 BYTE) NOT NULL,
	"STATE" VARCHAR2(20 BYTE) NOT NULL,
	"ZIP" NUMBER(10,0) NOT NULL,
	PRIMARY KEY ("CUSTOMER_ID")
);

--Products
create table "PRODUCTS" (
	"PRODUCT_ID" NUMBER(10,0) NOT NULL,
	"PRODUCT_NAME" VARCHAR2(20 BYTE) NOT NULL,
	"PRICE" NUMBER(10,0) NOT NULL,
	"IN_STOCK" NUMBER(10,0) NOT NULL,
	PRIMARY KEY ("PRODUCT_ID")
);

--Orders
create table "ORDERS" (
	"ORDER_ID" NUMBER(10,0) NOT NULL,
	"SALES_ID" NUMBER(10,0) NOT NULL,
	"PRODUCT_ID" NUMBER(10,0) NOT NULL,
	"CUSTOMER_ID" NUMBER(10,0) NOT NULL,
	PRIMARY KEY ("ORDER_ID"),
	FOREIGN KEY ("SALES_ID") REFERENCES "SALES1" ("SALES_ID"),
	FOREIGN KEY ("PRODUCT_ID") REFERENCES "PRODUCTS" ("PRODUCT_ID"),
	FOREIGN KEY ("CUSTOMER_ID") REFERENCES "CUSTOMER" ("CUSTOMER_ID")
);

-- Create auto increment sequence for primary keys on each table
CREATE SEQUENCE manager_id_seq START WITH 1000 INCREMENT BY 1;
CREATE SEQUENCE new_employee_id_seq START WITH 1000 INCREMENT BY 1;
CREATE SEQUENCE sales_id_seq START WITH 1000 INCREMENT BY 1;
CREATE SEQUENCE customer_id_seq START WITH 1000 INCREMENT BY 1;
CREATE SEQUENCE product_id_seq START WITH 1000 INCREMENT BY 1;
CREATE SEQUENCE order_id_seq START WITH 1000 INCREMENT BY 1;

-- Auto-populate primary key
CREATE OR REPLACE TRIGGER manager_on_insert
  BEFORE INSERT ON "MANAGER"
  FOR EACH ROW
BEGIN
  SELECT manager_id_seq.nextval
  INTO :new.MANAGER_ID
  FROM dual;
END;

-- Auto-populate primary key
CREATE OR REPLACE TRIGGER employee_on_insert
  BEFORE INSERT ON "EMPLOYEE"
  FOR EACH ROW
BEGIN
  SELECT new_employee_id_seq.nextval
  INTO :new.EMPLOYEE_ID
  FROM dual;
END;

-- Auto-populate primary key
CREATE OR REPLACE TRIGGER sales_on_insert
  BEFORE INSERT ON "SALES1"
  FOR EACH ROW
BEGIN
  SELECT sales_id_seq.nextval
  INTO :new.SALES_ID
  FROM dual;
END;

-- Auto-populate primary key
CREATE OR REPLACE TRIGGER customer_on_insert
  BEFORE INSERT ON "CUSTOMER"
  FOR EACH ROW
BEGIN
  SELECT customer_id_seq.nextval
  INTO :new.CUSTOMER_ID
  FROM dual;
END;

-- Auto-populate primary key
CREATE OR REPLACE TRIGGER products_on_insert
  BEFORE INSERT ON "PRODUCTS"
  FOR EACH ROW
BEGIN
  SELECT product_id_seq.nextval
  INTO :new.PRODUCT_ID
  FROM dual;
END;

-- Auto-populate primary key
CREATE OR REPLACE TRIGGER orders_on_insert
  BEFORE INSERT ON "ORDERS"
  FOR EACH ROW
BEGIN
  SELECT order_id_seq.nextval
  INTO :new.ORDER_ID
  FROM dual;
END;

-- Populate Orders table when a sale is entered in Sales1 table
CREATE OR REPLACE TRIGGER update_orders_on_new_sale
	AFTER INSERT ON "SALES1"
	FOR EACH ROW
BEGIN
	INSERT INTO ORDERS(SALES_ID,PRODUCT_ID,CUSTOMER_ID)
	VALUES(:new.SALES_ID,:new.PRODUCT_ID,new:CUSTOMER_ID);
END;


/* Procedure, If employee does not have an assigned manager,
one will automatically be assigned based on the first letter of the last name
*/
create or replace procedure add_manager as
	BEGIN
		declare
		cursor add_manager_cursor is
		select LAST_NAME
		from employee
		for update of employee.MANAGER_ID;

		lastName employee.LAST_NAME%type;
		firstChar employee.LAST_NAME%type;

	BEGIN
		open add_manager_cursor;
		loop
		FETCH add_manager_cursor into lastName;
		firstChar := UPPER (SUBSTR(lastName, 1, 1));
		exit when add_manager_cursor%NOTFOUND;

		-- Last name begins with A - D, assigned manager 1000
		IF firstChar between 'A' and 'D' then
		update Employee
			set MANAGER_ID = 1000
			where current of add_manager_cursor;

		-- Last name begins with E - H, assigned manager 1001
		ELSIF firstChar between 'E' and 'H' then
		update Employee
			set MANAGER_ID = 1001
			where current of add_manager_cursor;

		-- Last name begins with I - L, assigned manager 1002
		ELSIF firstChar between 'I' and 'L' then
		update Employee
			set MANAGER_ID = 1002
			where current of add_manager_cursor;

		-- Last name begins M - P, assigned manager 1003
		ELSIF firstChar between 'M' and 'P' then
		update Employee
			set MANAGER_ID = 1003
			where current of add_manager_cursor;

		-- Last name begins Q - T, assigned manager 1004
		ELSIF firstChar between 'Q' and 'T' then
		update Employee
			set MANAGER_ID = 1004
			where current of add_manager_cursor;

		-- Last name begins U or later, assigned manager 1005
		else
		update Employee
			set MANAGER_ID = 1005
			where current of add_manager_cursor;

	END IF;
	end loop;
	COMMIT;
	CLOSE add_manager_cursor;
	END;
	END;

-- Procedure, updates reorder needs based on current inventory of products
create or replace procedure order_inventory as
	begin
		declare
		cursor inventory_cursor is
		select IN_STOCK, PRODUCT_ID, PRODUCT_NAME from PRODUCTS;
		numItems PRODUCTS.IN_STOCK%type;
		itemID PRODUCTS.PRODUCT_ID%type;
		itemName PRODUCTS.PRODUCT_NAME%type;
	begin
		open inventory_cursor;
		loop
		fetch inventory_cursor into numItems, itemID, itemName;
		exit when inventory_cursor%NOTFOUND;
		DBMS_OUTPUT.PUT_LINE('Please reorder '||(50-numItems)||' of '||itemName||
			 ' (product ID '||itemID||')');
		end loop;
		close inventory_cursor;
	end;
	end;


-- View displaying any products with fewer than 10 items in stock
create or replace view low_inventory as 
	select PRODUCTS.PRODUCT_ID "Product ID", PRODUCTS.PRODUCT_NAME "Name", PRODUCTS.IN_STOCK 
	"Items in stock" from PRODUCTS
	WHERE in_stock < 10;

-- View displaying all employees by manager
create or replace view employee_manager as
	select employee.EMPLOYEE_ID "Employee ID",
	employee.FIRST_NAME||' '||employee.LAST_NAME "Employee Name",
	manager.FIRST_NAME||' '||manager.LAST_NAME "Manager Name",
	manager.MANAGER_ID "Manager ID"
	from employee
	join manager on employee.MANAGER_ID = manager.MANAGER_ID
	order by manager.MANAGER_ID;









