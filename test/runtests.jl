using FytcAgentMemory
using FytcAgentBase
using Test

# A memory type with no method specializations, to exercise the base fallbacks.
struct _BareMemory <: AbstractMemory end

@testset "FytcAgentMemory" begin
    @testset "ShortTermMemory recency window" begin
        mem = ShortTermMemory(; capacity = 3)
        @test isempty(recall(mem))
        for s in ["a", "b", "c", "d"]
            remember!(mem, s)
        end
        # capacity 3 => oldest ("a") dropped.
        @test length(mem.records) == 3
        @test [r.content for r in recall(mem; limit = 10)] == ["b", "c", "d"]
        # recall returns the most recent `limit`, newest last.
        @test [r.content for r in recall(mem; limit = 2)] == ["c", "d"]
        # A query does NOT filter short-term memory (it's a recency window).
        @test [r.content for r in recall(mem, "nonsense"; limit = 2)] == ["c", "d"]
        @test_throws ConfigError ShortTermMemory(; capacity = 0)
        reset!(mem)
        @test isempty(mem.records)
    end

    @testset "EntityMemory keyed + keyword recall" begin
        mem = EntityMemory()
        remember!(mem, "PostgreSQL"; key = "db_choice")
        remember!(mem, "Ada Lovelace"; key = "project_lead")
        # Exact-key hit.
        hit = recall(mem, "db_choice")
        @test length(hit) == 1 && hit[1].content == "PostgreSQL"
        # Case-insensitive substring against keys.
        kw = recall(mem, "lead")
        @test length(kw) == 1 && kw[1].key == "project_lead"
        # Substring against facts.
        @test recall(mem, "postgres")[1].key == "db_choice"
        # No key => ConfigError.
        @test_throws ConfigError remember!(mem, "orphan")
        reset!(mem)
        @test isempty(recall(mem))
    end

    @testset "EntityMemory persists across runs (long-term, no RAG)" begin
        path = tempname() * ".toml"
        try
            m1 = EntityMemory(; path = path)
            remember!(m1, "PostgreSQL"; key = "db_choice")
            @test isfile(path)
            # A fresh instance = a later run; it reloads from disk.
            m2 = EntityMemory(; path = path)
            @test recall(m2, "db_choice")[1].content == "PostgreSQL"
            @test occursin("persisted", sprint(show, m2))
        finally
            isfile(path) && rm(path)
        end
    end

    @testset "Memory generics fall back to ConfigError" begin
        m = _BareMemory()
        @test_throws ConfigError remember!(m, "x")
        @test_throws ConfigError recall(m)
        @test_throws ConfigError reset!(m)
    end
end

@testset "Aqua quality" begin
    import Aqua
    Aqua.test_all(FytcAgentMemory; ambiguities = false)
end
