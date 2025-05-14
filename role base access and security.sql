-- 1. Create roles
CREATE ROLE 'AdminRole';
CREATE ROLE 'VendorRole';

-- 2. Create users
CREATE USER 'admin_user'@'localhost' IDENTIFIED BY 'admin@123';
CREATE USER 'vendor_user'@'localhost' IDENTIFIED BY 'vendor@123';

-- 3. Grant roles to users
GRANT 'AdminRole' TO 'admin_user'@'localhost';
GRANT 'VendorRole' TO 'vendor_user'@'localhost';

-- 4. Grant privileges to roles
GRANT SELECT, INSERT, UPDATE, DELETE ON zeptoDB.Users TO 'AdminRole';
GRANT SELECT, UPDATE ON zeptoDB.Products TO 'AdminRole';
GRANT SELECT, UPDATE ON zeptoDB.Inventory TO 'VendorRole';

-- 5. Revoke specific privilege
REVOKE INSERT ON zeptoDB.Users FROM 'AdminRole';

-- 6. Set role (optional within session if required)
SET ROLE 'AdminRole';
