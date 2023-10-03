@testset "Extend number of rounds with source_exec_folder" begin
    r = pigeons(; target = toy_mvn_target(1), checkpoint = true, on = ChildProcess())
    new_exec = Pigeons.increment_n_rounds!(r.exec_folder, 2)
    pt = pigeons(new_exec)
    @test pt.inputs.n_rounds == 12
end

@testset "Extend number of rounds with PT object" begin
    pt = pigeons(; target = toy_mvn_target(1), checkpoint = true)
    pt = Pigeons.increment_n_rounds!(pt, 2)
    pt = pigeons(pt)
    @test pt.inputs.n_rounds == 12
end

@testset "Extend number of rounds with PT object, on ChildProcess" begin
    pt = pigeons(; target = toy_mvn_target(1), checkpoint = true)
    pt = Pigeons.increment_n_rounds!(pt, 2)
    r = pigeons(pt.exec_folder, ChildProcess())
    pt = load(r)
    @test pt.inputs.n_rounds == 12
end

@testset "Complex example of increasing number of rounds many times" begin
    pt = pigeons(target = toy_mvn_target(1), checkpoint = true) 
    @test pt.shared.iterators.round == 10
    pt = Pigeons.increment_n_rounds!(pt, 1) # pt.inputs.n_rounds += 1
    pigeons(pt)
    @test pt.shared.iterators.round == 11
    pt = PT("results/latest")
    pt = Pigeons.increment_n_rounds!(pt, 2) # pt.inputs.n_rounds += 2
    pt = pigeons(pt)
    @test pt.shared.iterators.round == 13
end

function compare_pts(p1, p2) 
    @test p1.replicas == p2.replicas 
    @test p1.shared == p2.shared 
    @test p1.reduced_recorders == p2.reduced_recorders 
end

@testset "Checkpoints" begin
    for target in [toy_mvn_target(2), Pigeons.toy_turing_unid_target()]
        p1 = pigeons(; target, checkpoint = true) 
        p2 = PT("results/latest")
        compare_pts(p1, p2)

        r = pigeons(; target, checkpoint = true, on = ChildProcess(n_local_mpi_processes = 2))
        p3 = load(r) 
        compare_pts(p1, p3)
    end
end

