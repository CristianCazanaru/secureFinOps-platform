
INSERT INTO users (username, nume, prenume, socialsecno)
VALUES (
    'smith.j',
    encrypt_nume('Jhon', 'SecretKey1234567'),
    encrypt_nume('Smith', 'SecretKey1234567'),
    encrypt_cnp('1234567890123', 'SecretKey1234567')
);


-- Select the inserted user and decrypt the fields to verify correctness
SELECT
    userid,
    username,
    decrypt_nume(nume, 'SecretKey1234567')        AS nume,
    decrypt_nume(prenume, 'SecretKey1234567')     AS prenume,
    decrypt_cnp(socialsecno, 'SecretKey1234567')  AS cnp
FROM users;

-- Select all users to see the encrypted data in the table
SELECT * FROM users;