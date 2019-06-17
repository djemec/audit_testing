# audit_testing
test for autowrite of table auditing
creates trigger sql to write transactional logs for database changes in MySQL 7.2+

Note that the prepare statement cannot be used for "create trigger" statements so that must be done manually