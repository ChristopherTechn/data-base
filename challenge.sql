CREATE TABLE Books (
    BookID INT PRIMARY KEY,
    Title VARCHAR(100),
    Author VARCHAR(100),
    PublicationYear INT,
    Status VARCHAR(10)
);

CREATE TABLE Members (
    MemberID INT PRIMARY KEY,
    Name VARCHAR(100),
    Address VARCHAR(100),
    ContactNumber VARCHAR(20)
);

CREATE TABLE Loans (
    LoanID INT PRIMARY KEY,
    BookID INT,
    MemberID INT,
    LoanDate DATE,
    ReturnDate DATE,
    FOREIGN KEY (BookID) REFERENCES Books(BookID),
    FOREIGN KEY (MemberID) REFERENCES Members(MemberID)
);
INSERT INTO Books (BookID, Title, Author, PublicationYear, Status)
VALUES
    (1, 'Book w', 'james', 2001, 'Available'),
    (2, 'Book x', 'john', 2002, 'Available'),
    (3, 'Book y', 'jonah', 2003, 'Available'),
    (4, 'Book z', 'job', 2004, 'Available');

INSERT INTO Members (MemberID, Name, Address, ContactNumber)
VALUES
    (1, 'christopher', '23 Nairobi', '0769311580'),
    (2, 'martin', '39 thika', '0702976882'),
    (3, 'goliath', '789 nyeri', '0726099676'),
     (4, 'david', '123 nyeri', '0877366363');

INSERT INTO Loans (LoanID, BookID, MemberID, LoanDate, ReturnDate)
VALUES
    (1, 1, 1, '2023-05-01', '2023-05-15'),
    (2, 2, 1, '2023-06-01', '2023-06-15'),
    (3, 3, 2, '2023-05-10', '2023-05-30'),
    (4, 4, 3, '2023-06-05', NULL);

SELECT * FROM Loans
SELECT * FROM Members
SELECT * FROM Books

  --creating trigger updating status column

CREATE TRIGGER updatebook-status
ON Loans
INSTEAD OF INSERT, UPDATE, DELETE
AS
BEGIN
  DECLARE @book_status VARCHAR(10)
  
  -- Update the Status column for loaned books
  UPDATE Books
  SET Status = 'Loaned'
  FROM Books
  INNER JOIN inserted ON Books.BookID = inserted.BookID

  -- Update the Status column for returned books
  UPDATE Books
  SET Status = 'Available'
  FROM Books
  INNER JOIN deleted ON Books.BookID = deleted.BookID
END
GO

SELECT * FROM Books;
SELECT * FROM Members;
SELECT * FROM Loans;

--CTE to retrieves names of all members who have borrowed 3 books
WITH BorrowCounts AS (
  SELECT MemberID, COUNT(*) AS NumOfBorrows
  FROM Loans
  GROUP BY MemberID
  HAVING COUNT(*) >= 3
)
SELECT M.Name
FROM Members M
INNER JOIN BorrowCounts B ON M.MemberID = B.MemberID;


--a vieew that displays details of all overdue loans,including book title,member name and no of over due days

CREATE VIEW Overdue-LoansView AS
SELECT B.Title AS BookTitle, M.Name AS MemberName, DATEDIFF(DAY, L.LoanDate, GETDATE()) AS OverdueDays
FROM Loans L
JOIN Books B ON L.BookID = B.BookID
JOIN Members M ON L.MemberID = M.MemberID
WHERE DATEDIFF(DAY, L.LoanDate, GETDATE()) > 30;


--trigger to prevent borrowing more than 3 books from the libary
CREATE TRIGGER Prevent-Excessive_Borrowing
ON Loans
FOR INSERT
AS
BEGIN
    DECLARE @MemberID INT;
    DECLARE @TotalLoans INT;

    SELECT @MemberID = MemberID
    FROM inserted;

    SELECT @TotalLoans = COUNT(*)
    FROM Loans
    WHERE MemberID = @MemberID;

    IF @TotalLoans >= 3
    BEGIN
        RAISERROR('Can not borrow more than three books at a time.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;