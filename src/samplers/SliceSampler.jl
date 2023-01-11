"""
Slice sampler based on [Neal, 2003](https://projecteuclid.org/journals/annals-of-statistics/volume-31/issue-3/Slice-sampling/10.1214/aos/1056562461.full).
"""
@kwdef @concrete mutable struct SliceSampler
    w = 1.0 # initial slice size
    p = 10 # slices are no larger than 2^p * w
    dim_fraction = 1.0 # proportion of variables to update
    
    # Private (store information to avoid allocations)
    x_0 = [0.0]
    C = [0]
    x_1 = [0.0]
    Lvec = [0.0]
    Rvec = [0.0]
    x_1vec = [0.0]
end
# TODO: proper initialization


"""
$SIGNATURES 
"""
@provides explorer create_explorer(target, inputs) = SliceSampler() # TODO
create_state_initializer(target) = Ref(zeros(target)) # TODO
adapt_explorer(explorer::SliceSampler, _, _) = explorer 
explorer_recorder_builders(::SliceSampler) = [] 
regenerate!(explorer::SliceSampler, replica, shared) = @abstract

function step!(explorer::SliceSampler, replica, shared)
    log_potential = find_log_potential(replica, shared)
    explorer.C .= zeros(Int, Int64(ceil(length(replica.state) * explorer.dim_fraction))) # TODO: remove this allocation
    replica.state .= slice_sample(explorer, replica, log_potential)
end


"""
$SIGNATURES
Slice sample one point.
"""
function slice_sample(h::SliceSampler, replica, log_potential)
    h.x_0 .= replica.state
    dim_x = length(h.x_0)
    h.x_1 .= h.x_0
    g_x_0 = -log_potential(h.x_0)

    StatsBase.sample!(1:dim_x, h.C; replace = false) # coordinates to update
    for c in h.C # update each coordinate
        z = g_x_0 - rand(Exponential(1.0)) # log(y)
        L, R = slice_double(h, h.x_1, z, c, log_potential)
        h.x_1[c] = slice_shrink(h, h.x_1, z, L, R, c, log_potential)
    end
    return h.x_1
end


"""
$SIGNATURES
Double the current slice.
"""
function slice_double(h::SliceSampler, x_0, z, c::Integer, log_potential)
    U = rand()
    L = x_0[c] - h.w*U
    R = L + h.w
    K = h.p
    
    h.Lvec .= x_0
    h.Lvec[c] = L
    h.Rvec .= x_0
    h.Rvec[c] = R
    
    while (K > 0) && ((z < -log_potential(h.Lvec)) || (z < -log_potential(h.Rvec)))
        V = rand()
        if V <= 0.5
            L = L - (R - L)
            h.Lvec[c] = L
        else
            R = R + (R - L)
            h.Rvec[c] = R
        end
        K = K - 1
        
        
    end
    return(; L, R)
end


"""
$SIGNATURES
Shrink the current slice.
"""
function slice_shrink(h::SliceSampler, x_0, z, L, R, c::Int, log_potential)
    Lbar = L
    Rbar = R
    
    while true
        U = rand()
        x_1 = Lbar + U * (Rbar - Lbar)
        h.x_1vec .= x_0
        h.x_1vec[c] = x_1
        if (z < -log_potential(h.x_1vec)) && (slice_accept(h, x_0, x_1, z, L, R, c, log_potential))
            return x_1
        end
        if x_1 < x_0[c]
            Lbar = x_1
        else
            Rbar = x_1
        end
    end
    return x_1
end


"""
$SIGNATURES
Test whether to accept the current slice.
"""
function slice_accept(h::SliceSampler, x_0, x_1, z, L, R, c::Int, log_potential)
    Lhat = L
    Rhat = R
    h.Lvec .= x_0
    h.Lvec[c] = L
    h.Rvec .= x_0
    h.Rvec[c] = R
    
    D = false
    acceptable = true
    
    while Rhat - Lhat > 1.1 * h.w
        M = (Lhat + Rhat)/2.0
        if ((x_0[c] < M) && (x_1 >= M)) || ((x_0[c] >= M) && (x_1 < M))
            D = true
        end
        
        if x_1 < M
            Rhat = M
            h.Rvec[c] = Rhat
        else
            Lhat = M
            h.Lvec[c] = Lhat
        end
        
        if D && (z >= -log_potential(h.Lvec)) && (z >= -log_potential(h.Rvec))
            acceptable = false
            return acceptable
        end
    end
    return acceptable
end