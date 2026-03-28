# Core infrastructure module
from core.config import settings
from core.db_client import init_db, close_db
from core.middleware import verify_access_token, user_verification
