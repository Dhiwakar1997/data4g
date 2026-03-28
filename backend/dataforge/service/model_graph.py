from collections import deque

from dataforge.schemas.db_model import (
    DBModelSpec, Entity, Relationship,
    EntityStorageProjection, DBStorageProjection, DBIOPSProjection,
)


class ModelGraph:
    """
    BFS-based engine that propagates record counts from a central entity
    through the relationship graph using ratios, and calculates storage
    and IOPS projections.
    """

    def __init__(self, db_spec: DBModelSpec):
        self.spec = db_spec
        self._entities = {e.id: e for e in db_spec.entities}
        self._relationships = db_spec.relationships
        self._adjacency: dict[str, list[Relationship]] = {}
        for rel in self._relationships:
            self._adjacency.setdefault(rel.source_entity_id, []).append(rel)

    def get_central_entity(self) -> Entity | None:
        return next((e for e in self._entities.values() if e.is_central), None)

    def validate(self) -> list[str]:
        errors: list[str] = []

        # Check central entity
        centrals = [e for e in self._entities.values() if e.is_central]
        if len(centrals) == 0:
            errors.append("No central entity defined.")
        elif len(centrals) > 1:
            errors.append(f"Multiple central entities: {[e.name for e in centrals]}")

        # Check connectivity
        connected: set[str] = set()
        for r in self._relationships:
            connected.update([r.source_entity_id, r.target_entity_id])
        for eid, e in self._entities.items():
            if eid not in connected and not e.is_central:
                errors.append(f"Entity '{e.name}' is not connected to any other entity.")

        # Check FK references
        for e in self._entities.values():
            for f in e.fields:
                if f.key.key_type == "foreign":
                    ref_id = f.key.references_entity_id
                    if ref_id and ref_id not in self._entities:
                        errors.append(
                            f"Field '{e.name}.{f.name}' references non-existent entity '{ref_id}'."
                        )

        # Check PK exists on entities with incoming FKs
        entities_with_fk_targets: set[str] = set()
        for e in self._entities.values():
            for f in e.fields:
                if f.key.key_type == "foreign" and f.key.references_entity_id:
                    entities_with_fk_targets.add(f.key.references_entity_id)
        for eid in entities_with_fk_targets:
            entity = self._entities.get(eid)
            if entity and not entity.primary_key_fields:
                errors.append(f"Entity '{entity.name}' is referenced by FK but has no primary key.")

        return errors

    def calculate_record_counts(self, user_count: int) -> dict[str, int]:
        """BFS from central entity. Each relationship multiplies parent count by ratio."""
        central = self.get_central_entity()
        if not central:
            return {}

        counts: dict[str, int] = {central.id: user_count}
        visited: set[str] = {central.id}
        queue: deque[str] = deque([central.id])

        while queue:
            current_id = queue.popleft()
            for rel in self._adjacency.get(current_id, []):
                target_id = rel.target_entity_id
                if target_id not in visited:
                    counts[target_id] = int(counts[current_id] * rel.ratio)
                    visited.add(target_id)
                    queue.append(target_id)

        return counts

    def calculate_storage(self, user_count: int) -> DBStorageProjection:
        counts = self.calculate_record_counts(user_count)
        projections: list[EntityStorageProjection] = []
        total_data = 0
        total_index = 0
        total_records = 0

        for eid, count in counts.items():
            entity = self._entities[eid]
            avg_size = entity.avg_record_size_bytes
            data_size = count * avg_size

            # Index overhead: ~20% base + 5% per additional index
            index_count = len(entity.indexes) + sum(1 for f in entity.fields if f.indexed)
            index_ratio = 0.20 + (index_count * 0.05)
            index_overhead = int(data_size * min(index_ratio, 0.50))

            projections.append(EntityStorageProjection(
                entity_id=eid,
                entity_name=entity.name,
                record_count=count,
                avg_record_size_bytes=avg_size,
                data_size_bytes=data_size,
                index_overhead_bytes=index_overhead,
                total_size_bytes=data_size + index_overhead,
            ))
            total_data += data_size
            total_index += index_overhead
            total_records += count

        # WAL / journal estimate: ~10% of data size
        wal_bytes = int(total_data * 0.10)

        return DBStorageProjection(
            topology_component_id=self.spec.topology_component_id,
            database_id=self.spec.database_id,
            per_entity=projections,
            total_data_bytes=total_data,
            total_index_bytes=total_index,
            wal_journal_bytes=wal_bytes,
            total_storage_bytes=total_data + total_index + wal_bytes,
            total_records=total_records,
        )

    def calculate_iops(self, user_count: int, rw_ratio: float = 0.8) -> DBIOPSProjection:
        """Estimate IOPS from user count. ~10 ops/user/day average."""
        ops_per_sec = max(1, int(user_count * 10 / 86400))
        read_iops = int(ops_per_sec * rw_ratio)
        write_iops = int(ops_per_sec * (1 - rw_ratio))
        return DBIOPSProjection(
            read_iops=read_iops,
            write_iops=write_iops,
            total_iops=read_iops + write_iops,
            read_write_ratio=rw_ratio,
        )
