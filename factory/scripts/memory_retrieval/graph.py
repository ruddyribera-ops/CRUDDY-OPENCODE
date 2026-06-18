"""NetworkX graph for memory relationship expansion."""
from typing import Optional

import networkx as nx

from .models import MemoryRecord


class MemoryGraph:
    """NetworkX-backed graph for memory relationships."""

    def __init__(self):
        self._graph: nx.DiGraph = nx.DiGraph()

    def add_memory(self, memory: MemoryRecord) -> None:
        """Add a memory node to the graph."""
        self._graph.add_node(memory.id, memory=memory)

    def add_link(self, from_id: str, to_id: str) -> None:
        """Add a directed edge between two memory IDs."""
        if from_id in self._graph and to_id in self._graph:
            self._graph.add_edge(from_id, to_id)

    def get_neighbors(self, memory_id: str, depth: int = 1) -> list[str]:
        """Get neighbor memory IDs (1-hop by default)."""
        if memory_id not in self._graph:
            return []
        if depth == 1:
            return list(self._graph.successors(memory_id)) + list(self._graph.predecessors(memory_id))
        else:
            # For depth > 1, use ego_graph
            ego = nx.ego_graph(self._graph, memory_id, radius=depth)
            return [n for n in ego.nodes() if n != memory_id]

    def get_subgraph(self, memory_ids: list[str]) -> "MemoryGraph":
        """Get a subgraph containing only the specified memory IDs."""
        subgraph = MemoryGraph()
        subgraph._graph = self._graph.subgraph(memory_ids).copy()
        return subgraph

    def compute_boost_scores(self, memory_ids: list[str], boost: float = 0.1) -> dict[str, float]:
        """Compute boost scores for a list of memory IDs based on graph connectivity.

        Returns a dict mapping memory_id -> boost_score.
        Memories that are neighbors to high-scoring memories get boosted.
        """
        boost_scores: dict[str, float] = {mid: 0.0 for mid in memory_ids}

        for memory_id in memory_ids:
            neighbors = self.get_neighbors(memory_id, depth=1)
            for neighbor in neighbors:
                if neighbor in memory_ids:
                    boost_scores[neighbor] += boost

        return boost_scores

    def build_from_memories(self, memories: list[MemoryRecord]) -> None:
        """Build the graph from a list of MemoryRecords."""
        self._graph.clear()
        for memory in memories:
            self._graph.add_node(memory.id, memory=memory)

        for memory in memories:
            for link in memory.links:
                if link in self._graph:
                    self._graph.add_edge(memory.id, link)

    def is_empty(self) -> bool:
        """Check if the graph has any nodes."""
        return self._graph.number_of_nodes() == 0

    def node_count(self) -> int:
        """Return the number of nodes in the graph."""
        return self._graph.number_of_nodes()

    def edge_count(self) -> int:
        """Return the number of edges in the graph."""
        return self._graph.number_of_edges()

    def get_memory(self, memory_id: str) -> Optional[MemoryRecord]:
        """Get a memory by ID from the graph."""
        if memory_id in self._graph:
            return self._graph.nodes[memory_id].get("memory")
        return None
