import secrets
from cryptography.fernet import Fernet
fernet_key = Fernet.generate_key().decode()

secret_key = secrets.token_urlsafe(32)
print(f"AIRFLOW__CORE__FERNET_KEY={fernet_key}")
print(f"AIRFLOW__WEBSERVER__SECRET_KEY={secret_key}")
