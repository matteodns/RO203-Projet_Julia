# This file contains methods to solve an instance (heuristically or with CPLEX)
using CPLEX

TOL = 0.00001

"""
Solve an instance with CPLEX
"""
function cplexSolve(initMat::Matrix{Int64})

    # Create the model
    m = Model(CPLEX.Optimizer)

    # TODO

    N = Int64(size(initMat, 1))
    M = Int64(size(initMat, 2))

    @variable(m, x[1:N, 1:M], Bin)

    for j in 1:M
        for k in 1:N-2
            @constraint(m, sum(x[i, j] for i in k:k+2) >= 1)
            @constraint(m, sum(x[i, j] for i in k:k+2) <= 2)
        end
        @constraint(m, sum(x[i, j] for i in 1:N) == N/2)
    end

    for i in 1:N
        for k in 1:M-2
            @constraint(m, sum(x[i, j] for j in k:k+2) >= 1)
            @constraint(m, sum(x[i, j] for j in k:k+2) <= 2)
        end
        @constraint(m, sum(x[i, j] for j in 1:M) == M/2)
    end

    for i in 1:N
        for j in 1:M
            if initMat[i, j] == 0
                @constraint(m, x[i, j] == 0)
            end
            if initMat[i, j] == 1
                @constraint(m, x[i, j] == 1)
            end
        end
    end

    @objective(m, Min, x[1, 1])

    # Start a chronometer
    start = time()

    # Solve the model
    optimize!(m)

    # Return:
    # 1 - true if an optimum is found
    isOptimal = termination_status(m) == MOI.OPTIMAL

    # 2 - the resolution time
    resTime = time()-start

    # 3 - variables
    if primal_status(m) == MOI.FEASIBLE_POINT
        X = Matrix{Int64}(undef,N,M)
        for i in 1:N
            for j in 1:M
                X[i, j] = JuMP.value(x[i, j])
            end
        end
    else
        X = Matrix{Int64}(zeros(N, M))
    end


    return isOptimal, resTime, X
    
end

"""
Heuristically solve an instance
"""
function heuristicSolve()

    # TODO
    println("In file resolution.jl, in method heuristicSolve(), TODO: fix input and output, define the model")
    
end 

"""
Solve all the instances contained in "../data" through CPLEX and heuristics

The results are written in "../res/cplex" and "../res/heuristic"

Remark: If an instance has previously been solved (either by cplex or the heuristic) it will not be solved again
"""
function solveDataSet()

    dataFolder = "./data/"
    resFolder = "./res/"

    # Array which contains the name of the resolution methods
    resolutionMethod = ["cplex"]
    #resolutionMethod = ["cplex", "heuristique"]

    # Array which contains the result folder of each resolution method
    resolutionFolder = resFolder .* resolutionMethod

    # Create each result folder if it does not exist
    for folder in resolutionFolder
        if !isdir(folder)
            mkdir(folder)
        end
    end
            
    global isOptimal = false
    global solveTime = -1

    # For each instance
    # (for each file in folder dataFolder which ends by ".txt")
    for file in filter(x->occursin(".txt", x), readdir(dataFolder))  
        
        println("-- Resolution of ", file)

        # TODO

        initMat = readInputFile(dataFolder * file)
        
        # For each resolution method
        for methodId in 1:size(resolutionMethod, 1)
            
            outputFile = resolutionFolder[methodId] * "/" * file

            # If the instance has not already been solved by this method
            if !isfile(outputFile)
                
                fout = open(outputFile, "w")  

                resolutionTime = -1
                isOptimal = false
                
                # If the method is cplex
                if resolutionMethod[methodId] == "cplex"
                    
                    # TODO 
                    
                    # Solve it and get the results
                    isOptimal, resolutionTime = cplexSolve(initMat)[1], cplexSolve(initMat)[2]
                    
                    # If a solution is found, write it
                    if isOptimal

                        # TODO


                        solMat = cplexSolve(initMat)[3]
                        N = size(solMat, 1)
                        M = size(solMat, 2)
                        print(fout, "-- Resolution of " * file * "\n  ")
                        for j in 1:M
                            print(fout, "---")
                        end
                        print(fout, "  \n")
                        for i in 1:N
                            print(fout, "| ")
                            for j in 1:M
                                print(fout, " " *  string(solMat[i, j]) * " ")
                            end
                            print(fout, " |\n")
                        end
                        print(fout, "  ")
                        for j in 1:M
                            print(fout, "---")
                        end
                        print(fout, "  \n\n")
                        
                    end

                # If the method is one of the heuristics
                else
                    
                    isSolved = false

                    # Start a chronometer 
                    startingTime = time()
                    
                    # While the grid is not solved and less than 100 seconds are elapsed
                    while !isOptimal && resolutionTime < 100
                        
                        # TODO 
                        println("In file resolution.jl, in method solveDataSet(), TODO: fix heuristicSolve() arguments and returned values")
                        
                        # Solve it and get the results
                        isOptimal, resolutionTime = heuristicSolve()

                        # Stop the chronometer
                        resolutionTime = time() - startingTime
                        
                    end

                    # Write the solution (if any)
                    if isOptimal

                        # TODO
                        println("In file resolution.jl, in method solveDataSet(), TODO: write the heuristic solution in fout")
                        
                    end 
                end

                println(fout, "solveTime = ", resolutionTime) 
                println(fout, "isOptimal = ", isOptimal)
                
                # TODO
                
                close(fout)
            end


            # Display the results obtained with the method on the current instance
            #include(outputFile)
            println(resolutionMethod[methodId], " optimal: ", isOptimal)
            println(resolutionMethod[methodId], " time: " * string(round(solveTime, sigdigits=2)) * "s\n")
        end         
    end 
end
