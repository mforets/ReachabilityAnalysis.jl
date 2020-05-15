# ==================
# Inhomogeneous case
# ==================

# no invariant
function reach_inhomog_GLGM06!(F::Vector{ReachSet{N, Zonotope{N, VN, MN}}},
                               Ω0::Zonotope{N, VN, MN},
                               Φ::AbstractMatrix,
                               NSTEPS::Integer,
                               δ::Float64,
                               max_order::Integer,
                               X::Universe,
                               U::LazySet,
                               reduction_method::AbstractReductionMethod,
                               t0) where {N, VN, MN}

    # initial reach set
    Δt = t0 .. δ
    @inbounds F[1] = ReachSet(Ω0, Δt)

    Wk₊ = U
    Φ_power_k = copy(Φ)
    Φ_power_k_cache = similar(Φ)

    k = 2
    @inbounds while k <= NSTEPS
        Rₖ = _minkowski_sum(_linear_map(Φ_power_k, Ω0), Wk₊)
        Rₖ = _reduce_order(Rₖ, max_order, reduction_method)
        Δt += δ
        F[k] = ReachSet(Rₖ, Δt)

        Wk₊ = _minkowski_sum(Wk₊, _linear_map(Φ_power_k, U))
        Wk₊ = _reduce_order(Wk₊, max_order, reduction_method)

        mul!(Φ_power_k_cache, Φ_power_k, Φ)
        copyto!(Φ_power_k, Φ_power_k_cache)
        k += 1
    end
    return F
end

# with invariant
function reach_inhomog_GLGM06!(F::Vector{ReachSet{N, Zonotope{N, VN, MN}}},
                               Ω0::Zonotope{N, VN, MN},
                               Φ::AbstractMatrix,
                               NSTEPS::Integer,
                               δ::Float64,
                               max_order::Integer,
                               X::LazySet,
                               U::LazySet,
                               reduction_method::AbstractReductionMethod,
                               t0) where {N, VN, MN}

    # initial reach set
    Δt = t0 .. δ
    @inbounds F[1] = ReachSet(Ω0, Δt)

    Wk₊ = U
    Φ_power_k = copy(Φ)
    Φ_power_k_cache = similar(Φ)

    k = 2
    @inbounds while k <= NSTEPS
        Rₖ = _minkowski_sum(_linear_map(Φ_power_k, Ω0), Wk₊)
        Rₖ = _reduce_order(Rₖ, max_order, reduction_method)
        _is_intersection_empty(X, Rₖ) && break
        Δt += δ
        F[k] = ReachSet(Rₖ, Δt)

        Wk₊ = _minkowski_sum(Wk₊, _linear_map(Φ_power_k, U))
        Wk₊ = _reduce_order(Wk₊, max_order, reduction_method)

        mul!(Φ_power_k_cache, Φ_power_k, Φ)
        copyto!(Φ_power_k, Φ_power_k_cache)
        k += 1
    end
    if k < NSTEPS + 1
        resize!(F, k-1)
    end
    return F
end
