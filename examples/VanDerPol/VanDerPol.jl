# # Van der Pol oscillator
#md # [![](https://img.shields.io/badge/show-nbviewer-579ACA.svg)](@__NBVIEWER_ROOT_URL__/models/VanDerPol.ipynb)
#
#md # !!! note "Overview"
#md #     System type: polynomial continuous system\
#md #     State dimension: 2\
#md #     Application domain: Nonlinear physics
#
# The Van der Pol oscillator was introduced by the Dutch physicist Balthasar van der Pol.
# This is a famous model, typically investigated in the study of nonlinear dynamics.
# It has been used in several practical problems of engineering, e.g. circuits
# containing vacuum tubes. For more information on the model see the wikipedia article
# [Van der Pol oscillator](https://en.wikipedia.org/wiki/Van_der_Pol_oscillator).

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
# The system has a stable limit cycle. Such limit cycle becomes increasingly sharp
# for higher values of ``μ``. Here we consider the parameter ``μ = 1``.

#!jl using ReachabilityAnalysis, Plots

@taylorize function vanderpol!(dx, x, params, t)
    local μ = 1.0
    dx[1] = x[2]
    dx[2] = (μ * x[2]) * (1 - x[1]^2) - x[1]
    return dx
end

#jl function vanderpol()
#jl    X0 = Hyperrectangle(low=[1.25, 2.35], high=[1.55, 2.45])
#jl    ivp = @ivp(x' = vanderpol!(x), dim: 2, x(0) ∈ X0)
#jl    tspan = (0.0, 5.0)
#jl    return ivp, tspan
#jl end

# ## Specification
#
# We set the initial condition ``x(0) ∈ [1.25, 1.55]``, ``y(0) ∈ [2.35,2.45]``.
# The *unsafe set* is given by ``y ≥ 2.75`` for a time span ``[0, 7]``.
# In other words, we would like to prove that there doesn't exist a solution of
# the model with a ``y`` value which is greater than 2.75, for any initial condition
# on the given domain. Th time horizon of ``T = 7`` is chosen such that the oscillator
# can do at least one full cycle.

# ## Results

# We proceed by defining the initial conditions as a hyperrectangular set according
# to the problem's specifications. Then we build the initial-value problem and pass
# it to the `solve` function. We specify using `TMJets` algorithm with default options.

X0 = Hyperrectangle(low=[1.25, 2.35], high=[1.55, 2.45]) #!jl
prob = @ivp(x' = vanderpol!(x), dim=2, x(0) ∈ X0) #!jl
sol = solve(prob, T=7.0, alg=TMJets()); #!jl

# For further computations, it is convenient to work with a zonotopic overapproximation
# of the flowpipe.

solz = overapproximate(sol, Zonotope); #!jl

# The maximum value of variable ``y`` is obtained by computing the support function
# of the flowpipe along direction ``[0, 1]``:

ρ([0.0, 1.0], solz) #!jl

# That shows that the property is satisfied. Below we plot the flowpipe in the
# x-y plane, together with the horizontal line ``y = 2.75``.

plot(solz, vars=(1, 2), lw=0.2, xlims=(-2.5, 2.5), xlab="x", ylab="y") #!jl
plot!(x -> 2.75, color=:red, lab="y = 2.75", style=:dash, legend=:bottomright) #!jl

# ### Invariant Set
#
# We can use the reachability result to examine an invariant of the system. In
# other words, we can algorithmicallyprove that the flowpipe re-enters from where
# it started after giving one loop, using inclusion checks.

plot(solz, vars=(1, 2), lw=0.2, xlims=(0.0, 2.5), ylims=(1.6, 2.8), xlab="x", ylab="y") #!jl
plot!(X0, color=:orange, lab="X0") #!jl
plot!(solz[1:5], vars=(1, 2), color=:green, lw=1.0, alpha=0.5, lab="F[1:5]") #!jl
plot!(solz[200], vars=(1, 2), color=:red, lw=1.0, alpha=0.6, lab="F[200]") #!jl

# It is seen that the reach-set corresponding to the time-span

tspan(solz[200])  #!jl

# is included in the set union ``F[1] \cup \cdots \cup F[5]`` of previously
# computed reach-sets. Notice that all future trajectories starting from
# `solz[200]` are already covered by the flowpipe.

# ### Limit cycle

# To examine the limit cycle we can intersect a line segment perpendicular to the
# flowpipe, that will allow us to get a cross-section of the sets in order to prove
# that after one cycle the intersection segment actually shrinks. This approach
# is similar to the method of [Poincaré sections](https://en.wikipedia.org/wiki/Poincar%C3%A9_map).

line = LineSegment([1, 2.], [2., 2.5]) #!jl
plot(solz, vars=(1, 2), lw=0.2, xlims=(0.0, 2.5), ylims=(1.6, 2.8), xlab="x", ylab="y") #!jl
plot!(X0, color=:orange, lab="X0") #!jl
plot!(solz[1:5], vars=(1, 2), color=:green, lw=1.0, alpha=0.5, lab="F[1:5]") #!jl
plot!(solz[200], vars=(1, 2), color=:red, lw=1.0, alpha=0.6, lab="F[200]") #!jl
plot!(line, lw=2.0) #!jl

# Then we can define a function to get the cross section of the flowpipe. The
# function needs the flowpipe, a line segment that cuts the flowpipe and the
# indices of the subsets to cut.

function cross_section(line::LineSegment, fp, idx) #!jl
    p = VPolygon() #!jl
    for i in idx #!jl
        x = intersection(line, set(fp[i])) #!jl
        p = convex_hull(p, x) #!jl
    end #!jl
    vl = vertices_list(p) #!jl
    @assert length(vl) == 2 #!jl
    return LineSegment(vl[1], vl[2]) #!jl
end #!jl

# Then we can get the cross section of the first five sets and the last set,
# calling them `i1` and `i2` respectively.

ifirst = cross_section(line, solz, 1:5) #!jl
ilast = cross_section(line, solz, [200]) #!jl

# We can also calculate the length of each cross section, remember that the
# system is 2D, so the cross section will be a line segment.

lfirst = norm(ifirst.q - ifirst.p) #!jl
#-
llast = norm(ilast.q - ilast.p); #!jl

#-

plot(ifirst, lw=3.0, alpha=1.0, label="First subsets", legend=:bottomright) #!jl
plot!(ilast, lw=5.0, alpha=1.0, label="Last subset") #!jl

#-

# The inclusion check succeeds:

ilast ⊆ ifirst #!jl

# We can see, the cross section of the last subset is a subset of the first few
# sets, thus, the cycle will continue, presumably getting smaller each revolution.