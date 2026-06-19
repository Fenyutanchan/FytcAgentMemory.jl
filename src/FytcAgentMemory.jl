"""
    FytcAgentMemory

Concrete memories for the orchestration layer. All are dependency-light and
use **keyword / keyed recall — never embeddings**:

- [`ShortTermMemory`](@ref): an in-memory rolling recency window of records,
  accumulated across a crew's tasks within one `kickoff` (CrewAI working-memory
  semantics). Not persisted.
- [`EntityMemory`](@ref): a `key → fact` store the agent/tools read and update
  mid-run. Optionally backed by a TOML file on disk, which gives **persistent
  long-term memory** (facts survive across runs) *without* RAG — recall is exact
  key plus optional case-insensitive substring match.

These specialize the [`remember!`](@ref) / [`recall`](@ref) / [`reset!`](@ref)
generics declared in `FytcAgentBase`.
"""
module FytcAgentMemory

using Dates: DateTime, now
using FytcAgentBase
import TOML

export ShortTermMemory, EntityMemory

# ----------------------------------------------------------------------------
# ShortTermMemory — rolling recency window (in-memory, per kickoff)
# ----------------------------------------------------------------------------

"""
    ShortTermMemory(; capacity = 20)

A rolling window of the most recent [`MemoryRecord`](@ref)s, capped at
`capacity` (oldest entries drop off). Used as an agent's / crew's working memory
within one run; it is not persisted.

`recall` returns the most recent records (newest last) as working context — a
non-`nothing` `query` does **not** filter (short-term memory is a recency
window, not a search index; keyword search is [`EntityMemory`](@ref)'s job).
"""
mutable struct ShortTermMemory <: AbstractMemory
    records::Vector{MemoryRecord}
    capacity::Int

    function ShortTermMemory(; capacity::Integer = 20)
        capacity >= 1 ||
            throw(ConfigError("ShortTermMemory capacity must be >= 1, got $capacity"))
        return new(MemoryRecord[], Int(capacity))
    end
end

function FytcAgentBase.remember!(
    mem::ShortTermMemory,
    content;
    key::Union{Nothing,AbstractString} = nothing,
)
    record = MemoryRecord(string(content); key = key)
    push!(mem.records, record)
    # Trim from the front so only the most recent `capacity` records remain.
    while length(mem.records) > mem.capacity
        popfirst!(mem.records)
    end
    return record
end

function FytcAgentBase.recall(
    mem::ShortTermMemory,
    query = nothing;
    limit::Integer = 5,
)
    limit >= 0 || throw(ConfigError("recall limit must be >= 0, got $limit"))
    # Recency window: return the most recent `limit` records regardless of query.
    n = length(mem.records)
    return n <= limit ? copy(mem.records) : mem.records[(n - limit + 1):n]
end

FytcAgentBase.reset!(mem::ShortTermMemory) = (empty!(mem.records); mem)

Base.show(io::IO, mem::ShortTermMemory) =
    print(io, "ShortTermMemory(", length(mem.records), "/", mem.capacity, " record(s))")

# ----------------------------------------------------------------------------
# EntityMemory — key→fact store, optionally persisted to TOML (long-term)
# ----------------------------------------------------------------------------

"""
    EntityMemory(; path = nothing)

A `key → fact` store. With `path === nothing` it lives in memory only; with a
file `path` it loads any existing facts on construction and writes back after
every change, giving **persistent long-term memory** (facts survive across runs)
with no database and no embeddings.

`remember!(mem, fact; key)` stores `fact` under `key` (a `key` is required).
`recall(mem, query)` returns records by **exact key first**, then
case-insensitive substring match against keys and facts; `recall(mem)` returns
all facts.
"""
mutable struct EntityMemory <: AbstractMemory
    facts::Dict{String,String}
    path::Union{Nothing,String}

    function EntityMemory(; path::Union{Nothing,AbstractString} = nothing)
        facts = Dict{String,String}()
        if path !== nothing && isfile(path)
            loaded = TOML.parsefile(String(path))
            for (k, v) in loaded
                facts[String(k)] = string(v)
            end
        end
        return new(facts, path === nothing ? nothing : String(path))
    end
end

function _persist(mem::EntityMemory)
    mem.path === nothing && return mem
    open(mem.path, "w") do io
        TOML.print(io, mem.facts)
    end
    return mem
end

function FytcAgentBase.remember!(
    mem::EntityMemory,
    content;
    key::Union{Nothing,AbstractString} = nothing,
)
    key === nothing &&
        throw(ConfigError("EntityMemory.remember! requires a key (the entity name)"))
    fact = string(content)
    mem.facts[String(key)] = fact
    _persist(mem)
    return MemoryRecord(fact; key = key)
end

function FytcAgentBase.recall(
    mem::EntityMemory,
    query = nothing;
    limit::Integer = 5,
)
    limit >= 0 || throw(ConfigError("recall limit must be >= 0, got $limit"))
    if query === nothing
        records = [MemoryRecord(v; key = k) for (k, v) in mem.facts]
        return length(records) <= limit ? records : records[1:limit]
    end
    qs = string(query)
    # Exact key hit wins.
    if haskey(mem.facts, qs)
        return [MemoryRecord(mem.facts[qs]; key = qs)]
    end
    q = lowercase(qs)
    records = MemoryRecord[]
    for (k, v) in mem.facts
        (occursin(q, lowercase(k)) || occursin(q, lowercase(v))) &&
            push!(records, MemoryRecord(v; key = k))
        length(records) >= limit && break
    end
    return records
end

function FytcAgentBase.reset!(mem::EntityMemory)
    empty!(mem.facts)
    _persist(mem)
    return mem
end

Base.show(io::IO, mem::EntityMemory) = print(
    io,
    "EntityMemory(", length(mem.facts), " fact(s)",
    mem.path === nothing ? "" : ", persisted", ")",
)

end # module FytcAgentMemory
