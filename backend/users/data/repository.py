import re
from datetime import datetime
from users.data.model import User


class UserRepository:

    async def create_user(self, user: User) -> User:
        await user.insert()
        return user

    async def get_user_by_email_id(self, email_id: str) -> User | None:
        return await User.find_one(User.email_id == email_id)

    async def get_user_by_id(self, user_id: str) -> User | None:
        return await User.find_one(User.user_id == user_id, User.is_deleted == False)

    async def get_user_by_provider_id(self, provider_id: str, auth_provider: str) -> User | None:
        return await User.find_one(
            User.provider_id == provider_id,
            User.auth_provider == auth_provider,
        )

    async def update_user(self, user: User) -> User:
        user.updated_at = datetime.now()
        await user.save()
        return user

    async def delete_user(self, user_id: str) -> User | None:
        user = await self.get_user_by_id(user_id)
        if not user:
            return None
        user.is_deleted = True
        user.deleted_at = datetime.now()
        user.updated_at = datetime.now()
        await user.save()
        return user

    async def search_users(self, query: str, current_user_id: str) -> list[dict]:
        """Simple text search on first_name and email_id."""
        pattern = re.compile(f"^{re.escape(query)}", re.IGNORECASE)
        users = await User.find(
            {
                "$and": [
                    {"is_deleted": False},
                    {"user_id": {"$ne": current_user_id}},
                    {"$or": [
                        {"first_name": {"$regex": pattern}},
                        {"email_id": {"$regex": pattern}},
                    ]},
                ]
            }
        ).limit(20).to_list()

        return [
            {
                "user_id": u.user_id,
                "first_name": u.first_name,
                "last_name": u.last_name,
                "mutual_followers": 0,
                "mutual_following": 0,
                "is_following": False,
            }
            for u in users
        ]
