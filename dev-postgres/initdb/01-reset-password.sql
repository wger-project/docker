BEGIN;


-- Set password to adminadmin
UPDATE auth_user
    SET password = 'pbkdf2_sha256$1000000$Pw11yvSIktZVAx8Lcpaizx$dMqOh/9VoCkfxksY9Cm78p6LXvMrYZBoqP31z7TRCj4='
    WHERE username = 'admin';

-- Set tokens to known values
UPDATE authtoken_token
    SET key = '73f1ee4fbc4f58bfcd777755fc36c6260823a084'
    WHERE user_id = (SELECT id FROM auth_user WHERE username = 'admin');

UPDATE authtoken_token
    SET key = '31e2ea0322c07b9df583a9b6d1e794f7139e78d4'
    WHERE user_id = (SELECT id FROM auth_user WHERE username = 'user');

-- Mark the email addresses as verified
INSERT INTO account_emailaddress (email, verified, "primary", user_id)
SELECT u.email, true, true, u.id
  FROM auth_user u
 WHERE u.username IN ('admin', 'user')
   AND u.email <> ''
   AND NOT EXISTS (
       SELECT 1 FROM account_emailaddress e WHERE e.user_id = u.id
   );

UPDATE account_emailaddress
   SET verified = true
 WHERE user_id IN (SELECT id FROM auth_user WHERE username IN ('admin', 'user'));


COMMIT;