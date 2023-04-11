"""
Abstract type for variational references.
"""
abstract type VarReference end

"""
A variational family of reference distributions. 
Implementations should also satisfy the [`log_potential`](@ref) 
contract. 
"""
@informal var_reference begin
    
    """
    $SIGNATURES
    Choose on which rounds/scans to activate the variational reference.
    """
    activate_var_reference(var_reference, iterators) = @abstract
    
    """
    $SIGNATURES
    Update the variational reference and the annealing path. Returns the new annealing path.
    """
    update_reference!(reduced_recorders, var_reference, state) = @abstract

    """
    $SIGNATURES
    Specify the recorder builders for this variational reference family.
    """
    var_reference_recorder_builders(var_reference) = @abstract
    
    """
    $SIGNATURES
    Obtain one iid sample from the reference distribution specified by the variational family.
    """
    sample_iid!(var_reference::VarReference, replica) = @abstract
end


function update_path_if_needed!(path, reduced_recorders, iterators, var_reference, state) 
    if activate_var_reference(var_reference, iterators) 
        update_path_var_reference!(path, reduced_recorders, var_reference, state) 
    else 
        nothing
    end
end

function update_path_var_reference!(path, reduced_recorders, var_reference, state)
    update_reference!(reduced_recorders, var_reference, state)
    path = InterpolatingPath(var_reference, path.target)
end

@provides var_reference create_var_reference(inputs) = inputs.var_reference
