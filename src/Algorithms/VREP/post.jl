# ===========================
# Continous post interface
# ===========================

# this algorithm uses polygons (two dimensions) or polytopes (any dimension) in vertex representation
function post(alg::VREP{N}, ivp::IVP{<:AbstractContinuousSystem}, tspan;
              Δt0::TimeInterval=zeroI, kwargs...) where {N}

    ReachabilityAnalysis.@unpack δ, approx_model, static, dim = alg

    # TODO move up to main solve function
    if haskey(kwargs, :NSTEPS)
        NSTEPS = kwargs[:NSTEPS]
        T = NSTEPS * δ
    else
        # get time horizon from the time span imposing that it is of the form (0, T)
        T = _get_T(tspan, check_zero=true, check_positive=true)
        NSTEPS = ceil(Int, T / δ)
    end

    # normalize system to canonical form
    # x' = Ax, x in X, or
    # x' = Ax + u, x in X, u in U
    ivp_norm = _normalize(ivp)

    # homogeneize the initial-value problem
    if haskey(kwargs, :homogeneize) && kwargs[:homogeneize] == true
        ivp_norm = homogeneize(ivp_norm)
    end

    # discretize system
    ivp_discr = discretize(ivp_norm, δ, approx_model)
    Φ = state_matrix(ivp_discr)
    Ω0 = initial_state(ivp_discr)::VPOLY
    X = stateset(ivp_discr)

    # true <=> there is no input, i.e. the system is of the form x' = Ax, x ∈ X
    got_homogeneous = !hasinput(ivp_discr)

    # reconvert the set of initial states and state matrix, if needed
    Ω0 = _reconvert(Ω0, static, dim)
    Φ = _reconvert(Φ, static, dim)

    # preallocate output flowpipe
    VT = typeof(Ω0)
    F = Vector{ReachSet{N, VT}}(undef, NSTEPS)

    if got_homogeneous
        reach_homog_VREP!(F, Ω0, Φ, NSTEPS, δ, X, Δt0)
    else
        error("not implemented")
    end

    return Flowpipe(F)
end