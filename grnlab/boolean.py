"""Exact synchronous Boolean updates, complete cycles and basin enumeration.

This module evaluates the truth tables exported by the MATLAB/Octave code.
It does not substitute an independent implementation for the EPP-DP engine.
"""

from dataclasses import dataclass
import numpy as np


@dataclass
class Orbit:
    trajectory: np.ndarray
    cycle: np.ndarray
    transient_length: int

    @property
    def key(self):
        """Canonical cyclic rotation; all phases identify the same attractor."""
        rows = tuple(tuple(int(bit) for bit in state) for state in self.cycle)
        return min(rows[i:] + rows[:i] for i in range(len(rows)))


class BooleanNetwork:
    """Truth tables in the original F/varF/nv format, with zero-based nodes."""

    def __init__(self, F, varF, nv, names):
        self.F = np.asarray(F)
        self.varF = np.asarray(varF, dtype=int)
        self.nv = np.asarray(nv, dtype=int).ravel()
        self.names = list(names)
        self.n = len(self.nv)
        self.inputs = [self.varF[:k, i] - 1 for i, k in enumerate(self.nv)]
        self.tables = [
            np.asarray(self.F[: 2**k, i], dtype=np.uint8) for i, k in enumerate(self.nv)
        ]
        if len(names) != self.n:
            raise ValueError("One node name is required for each truth table")

    def step(self, state, clamps=None):
        """Update all nodes simultaneously; clamps hold at t=0 and thereafter."""
        x = np.asarray(state, dtype=np.uint8)
        single = x.ndim == 1
        x = np.atleast_2d(x).copy()
        for node, value in (clamps or {}).items():
            x[:, node] = value
        y = x.copy()
        for node, inputs in enumerate(self.inputs):
            if len(inputs):
                index = x[:, inputs] @ (2 ** np.arange(len(inputs) - 1, -1, -1))
                y[:, node] = self.tables[node][index]
        for node, value in (clamps or {}).items():
            y[:, node] = value
        return y[0] if single else y

    def orbit(self, state, clamps=None, max_steps=10000):
        """Return the transient and every state of the final periodic orbit."""
        x = np.asarray(state, dtype=np.uint8).copy()
        for node, value in (clamps or {}).items():
            x[node] = value
        seen, states = {}, []
        for _ in range(max_steps):
            key = x.tobytes()
            if key in seen:
                start = seen[key]
                return Orbit(
                    np.asarray(states + [x.copy()]), np.asarray(states[start:]), start
                )
            seen[key] = len(states)
            states.append(x.copy())
            x = self.step(x, clamps)
        raise RuntimeError("Attractor not reached within max_steps")

    def signed_edges(self):
        """Infer activation/inhibition/context dependence from each truth table."""
        edges = []
        for target, inputs in enumerate(self.inputs):
            for position, source in enumerate(inputs):
                bit = 1 << (len(inputs) - position - 1)
                zero = np.array([i for i in range(2 ** len(inputs)) if not i & bit])
                difference = (
                    self.tables[target][zero | bit].astype(int)
                    - self.tables[target][zero]
                )
                if not np.any(difference):
                    continue  # a declared but functionally irrelevant input
                sign = (
                    1
                    if np.all(difference >= 0)
                    else -1 if np.all(difference <= 0) else 0
                )
                edges.append((int(source), target, sign))
        return edges


def decode_policy(actions, n):
    """MATLAB actions 1..n mean SA0; n+1..2n mean SA1."""
    actions = np.asarray(actions, dtype=int).ravel()
    if np.any(actions < 1) or np.any(actions > 2 * n):
        raise ValueError("Invalid control action")
    nodes = (actions - 1) % n
    if len(set(nodes)) != len(nodes):
        raise ValueError("A policy must not clamp the same gene more than once")
    return {int(node): int(action > n) for node, action in zip(nodes, actions)}


def cycle_distance(left, right):
    """Mean normalized Hamming distance, minimized over relative cycle phases."""
    length = np.lcm(len(left), len(right))
    a = left[np.arange(length) % len(left)]
    return min(
        float(np.mean(a != right[(np.arange(length) + shift) % len(right)]))
        for shift in range(len(right))
    )


def exact_basins(network, fixed_inputs, extra_clamps=None):
    """Enumerate all starts for a small network with fixed external inputs.

    The T-helper example has 19 free bits: 524,288 starts. Additional fault
    clamps act on this same initial-state population, preserving paired counts.
    Successors are built in batches; the functional graph is resolved once.
    """
    free = [i for i in range(network.n) if i not in fixed_inputs]
    if len(free) > 20:
        raise ValueError("Exact enumeration is limited to 20 free Boolean variables")
    count = 1 << len(free)
    codes = np.arange(count, dtype=np.uint32)
    successor = np.empty(count, dtype=np.uint32)
    clamps = dict(fixed_inputs)
    clamps.update(extra_clamps or {})
    for first in range(0, count, 65536):
        chunk = codes[first : first + 65536]
        x = np.zeros((len(chunk), network.n), dtype=np.uint8)
        x[:, free] = ((chunk[:, None] >> np.arange(len(free))) & 1).astype(np.uint8)
        y = network.step(x, clamps)
        successor[first : first + len(chunk)] = y[:, free] @ (
            2 ** np.arange(len(free), dtype=np.uint32)
        )
    labels = np.full(count, -1, dtype=np.int32)
    visiting = np.full(count, -1, dtype=np.int32)
    cycles = []
    for start in range(count):
        if labels[start] >= 0:
            continue
        path, current = [], start
        while labels[current] < 0 and visiting[current] < 0:
            visiting[current] = len(path)
            path.append(current)
            current = int(successor[current])
        if labels[current] >= 0:
            label = labels[current]
        else:
            cycle = path[visiting[current] :]
            label = len(cycles)
            rows = np.zeros((len(cycle), network.n), dtype=np.uint8)
            rows[:, free] = (np.asarray(cycle)[:, None] >> np.arange(len(free))) & 1
            for node, value in clamps.items():
                rows[:, node] = value
            cycles.append(rows)
        labels[path] = label
        visiting[path] = -1
    sizes = np.bincount(labels, minlength=len(cycles))
    return {
        "cycles": cycles,
        "sizes": sizes,
        "labels": labels,
        "initial_states": count,
        "fixed_inputs": fixed_inputs,
    }
