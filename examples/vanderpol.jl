# # Van der Pol oscillator
#md # [![](https://img.shields.io/badge/show-nbviewer-579ACA.svg)](@__NBVIEWER_ROOT_URL__/../vanderpol.ipynb)
#
#md # !!! note "Overview"
#md #     system type: polynomial continuous system\
#md #     state dimension: 2
#
# The Van der Pol oscillator was introduced by the Dutch physicist Balthasarvan der Pol.
# For more information on the model see
# [Wikipedia](https://en.wikipedia.org/wiki/Van_der_Pol_oscillator).

# ## Dynamics
#
# The dynamics of the Van der Pol oscillator are described by the following ODE with
# two variables:
#
# ```math
# \begin{aligned}
#   \dot{x} &= y \\
#   \dot{y} &= \mu (1 - x^2) y - x
# \end{aligned}
# ```
# The system has a stable limit cycle however that becomes increasingly sharp
# for higher values of ``μ``. We consider the parameter ``μ = 1``.

#!jl using ReachabilityAnalysis, Plots

@taylorize function vanderpol!(dx, x, params, t)
    local μ = 1.0
    dx[1] = x[2]
    dx[2] = (μ * x[2]) * (1 - x[1]^2) - x[1]
    return dx
end

#jl function vanderpol()
#jl    X0 = Hyperrectangle(low=[1.25, 2.35], high=[1.55, 2.45])
#jl    ivp = @ivp(x' = vanderPol!(x), dim: 2, x(0) ∈ X0)
#jl    tspan = (0.0, 5.0)
#jl    return ivp, tspan
#jl end

# ## Specification
#
# We set the initial condition ``x(0) ∈ [1.25, 1.55]``, ``y(0) ∈ [2.35,2.45]``.
# The *unsafe set* is given by ``y ≥ 2.75`` for a time horizon ``[0, 7]``.
# In other words, we would like to prove that there doesn't exist a solution of
# the model with a ``y`` value which is greater than 2.75, for any initial condition
# on the given domain.

# ## Results

# We proceed by defining the initial conditions as a hyperrectangular set according
# to the problem's specifications. Then we build the initial-value problem which
# is then passed to the `solve` function. We specify using `TMJets` algorithm with
# default options.

X0 = Hyperrectangle(low=[1.25, 2.35], high=[1.55, 2.45]) #!jl
prob = @ivp(x' = vanderpol!(x), dim=2, x(0) ∈ X0) #!jl
sol = solve(prob, T=7.0, alg=TMJets()); #!jl

# For further computations, it is convenient to work with a zonotopic overapproximation
# of the flowpipe.

solz = overapproximate(sol, Zonotope); #!jl

# The maximum value of variable ``y`` is obtained by computing the support function
# of the flowpipe along direction ``[0, 1]``:

ρ([0.0, 1.0], solz) #!jl

# That shows that the property is satisfied. We now plot the flowpipe in the
# x-y plane, together with the horizontal line ``y = 2.75``.

plot(solz, vars=(1, 2), lw=0.2, xlims=(-2.5, 2.5), xlab="x", ylab="y") #!jl
plot!(x -> 2.75, color=:red, lab="y = 2.75", style=:dash, legend=:bottomright) #!jl

# ### Limit cycle
#
# We can use the reachability result to examine the limit cycle of the system. In
# other words, we can see that the flowpipe re-enters from where it started after
# giving one loop. This in fact constitutes a proof that the system has a limit cycle,
# and we can prove it using set inclusions.

plot(solz, vars=(1, 2), lw=0.2, xlims=(0.0, 2.5), ylims=(1.6, 2.8), xlab="x", ylab="y") #!jl
plot!(X0, color=:orange, lab="X0") #!jl

# ### Performance tips

sol = solve(prob, T=7.0, alg=TMJets(orderT=7, orderQ=1)) #!jl