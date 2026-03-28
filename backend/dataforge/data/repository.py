from datetime import datetime
from dataforge.data.model import Project, ProjectMember


class ProjectRepository:

    async def create_project(self, project: Project) -> Project:
        await project.insert()
        return project

    async def get_project_by_id(self, project_id: str) -> Project | None:
        return await Project.find_one(
            Project.project_id == project_id,
            Project.is_deleted == False,
        )

    async def list_projects(self, skip: int = 0, limit: int = 50) -> tuple[list[Project], int]:
        query = Project.find(Project.is_deleted == False).sort("-created_at")
        total = await query.count()
        projects = await query.skip(skip).limit(limit).to_list()
        return projects, total

    async def list_projects_for_user(self, user_id: str, skip: int = 0, limit: int = 50) -> tuple[list[Project], int]:
        """List projects the user owns or is a member of."""
        memberships = await ProjectMember.find(
            ProjectMember.user_id == user_id,
        ).to_list()
        project_ids = [m.project_id for m in memberships]

        query = Project.find(
            {"$and": [
                {"project_id": {"$in": project_ids}},
                {"is_deleted": False},
            ]}
        ).sort("-created_at")
        total = await query.count()
        projects = await query.skip(skip).limit(limit).to_list()
        return projects, total

    async def update_project(self, project: Project) -> Project:
        project.updated_at = datetime.now()
        await project.save()
        return project

    async def delete_project(self, project_id: str) -> Project | None:
        project = await self.get_project_by_id(project_id)
        if not project:
            return None
        project.is_deleted = True
        project.updated_at = datetime.now()
        await project.save()
        return project


class MemberRepository:

    async def add_member(self, member: ProjectMember) -> ProjectMember:
        await member.insert()
        return member

    async def get_member(self, project_id: str, user_id: str) -> ProjectMember | None:
        return await ProjectMember.find_one(
            ProjectMember.project_id == project_id,
            ProjectMember.user_id == user_id,
        )

    async def list_members(self, project_id: str) -> list[ProjectMember]:
        return await ProjectMember.find(
            ProjectMember.project_id == project_id,
        ).to_list()

    async def update_member(self, member: ProjectMember) -> ProjectMember:
        member.updated_at = datetime.now()
        await member.save()
        return member

    async def remove_member(self, project_id: str, user_id: str) -> bool:
        member = await self.get_member(project_id, user_id)
        if not member:
            return False
        await member.delete()
        return True

    async def remove_all_members(self, project_id: str):
        """Remove all members when a project is deleted."""
        await ProjectMember.find(
            ProjectMember.project_id == project_id,
        ).delete()
