-- Creates a table to be used to store PSTN information and some user infomation

CREATE TABLE PhoneNumbers (
PSTNnumber int NOT NULL PRIMARY KEY,
UsedBy varchar(MAX),
ReservedFor varchar(MAX),
CountryCode int
);

