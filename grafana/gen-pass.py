# /// script
# requires-python = ">=3.12"
# dependencies = [
#     "bcrypt",
# ]
# ///

#
# Run "uv run gen-pass.py" to generate a bcrypt password hash
#

import getpass
import bcrypt

password = getpass.getpass("password: ")
hashed_password = bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt())
print(hashed_password.decode())

