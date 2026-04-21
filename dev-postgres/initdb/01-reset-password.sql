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

-- UPDATE core_userprofile
--   SET email_verified = true
--    WHERE id IN (SELECT id FROM auth_user WHERE username IN ('admin', 'user'));


COMMIT;