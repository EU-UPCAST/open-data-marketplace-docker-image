#!/usr/bin/env python3
# generate-mysql-password.py

import random
import string
import os

secret_file = os.environ.get('SECRET_FILE', '/run/secrets/mysql_root_password/password')
# Check if the secret file already exists
if not os.path.exists(secret_file):
    # Generate a random password
    password = ''.join(random.choices(string.ascii_letters + string.digits, k=16))

    # Store the password in the specified file
    with open(secret_file, 'w') as file:
        file.write(password)

    # Output the password for verification (optional)
    print(f"Generated MySQL root password: {password}")
else:
    # Output a message indicating that the password already exists
    print(f"Using existing MySQL root password from {secret_file}")