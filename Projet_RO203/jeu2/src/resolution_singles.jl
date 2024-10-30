# This file contains methods to solve an instance (heuristically or with CPLEX)
using CPLEX

include("generation_singles.jl")

TOL = 0.00001

"""
Fonction récursive qui construit un ensemble connexe

Arguments :
y = matrice où les éléments valent 1 si la case est masquée, zero sinon
i et j = coordonnées de la case à partir de laquelle on construit l'ensemble connexe
C = une liste de paire qui représente les coordonnées des éléments de notre ensemble connexe 

Renvoie rien mais ajoute à chaque itération i,j et ses voisins à la L1 et L2
"""
function add_connexe(y::Matrix{Int64}, i::Int64, j::Int64, C=Vector{Vector{Int64}})
    N=size(y, 1)
    if i>1 && y[i-1, j]==0 && [i-1, j] not in C 
        C.append([i-1,j])
        add_connexe(y, i-1, j, C)
    end
    if j>1 && y[i, j-1]==0 && [i, j-1] not in C
        C.append([i, j-1])
        add_connexe(y, i, j-1, C)
    end
    if i<N && y[i+1, j]==0 && [i+1, j] not in C
        C.append([i+1, j])
        add_connexe(y, i+1, j, C)
    end
    if j<N && y[i, j+1]==0 && [i, j+1] not in C
        C.append([i, j+1])
        add_connexe(y, i, j+1, C)
    end
end

"Vérifie si l'ensemble connexe décrit par C fait bient la même longueur que l'ensemble des cases visibles (dans y)"
function is_connexe(y::Matrix{Int64}, C::Vector{Vector{Int64}})
    sum_visible = 0
    for case in y 
        if case==0
            sum_visible+=1
        end
    end
    
    return length(C)==sum_visible
end


"""
Solve an instance with CPLEX
"""
function cplexSolve(initMat::Matrix{Int64})

    # Create the model
    m = Model(CPLEX.Optimizer)

    # TODO

    N = Int64(size(initMat,1))

    @variable(m, y[1:N, 1:N], Bin)

    # Maximum une fois le meme nombre par ligne et colonne
    for i in 1:N 
        for k in 1:N
            @constraint(m, sum((1-y[i,j]) for j in 1:N if initMat[i, j]==k) <= 1)
            @constraint(m, sum((1-y[j,i]) for j in 1:N if initMat[j, i]==k) <= 1)
        end
    end

    # Pas deux cases masquées d'affilée
    for i in 1:N 
        for j in 1:N-1
            @constraint(m, y[i, j]+y[i, j+1] <= 1)
            @constraint(m, y[j, i]+y[j+1, i] <= 1)
        end
    end


    # Verifier partiellement la connexité : empêcher les diagonales de cases masquées
    for i in 1:N-1
        @constraint(m, sum(y[i+k, 1+k] for k in 0:N-i) <= N-i-1)
        @constraint(m, sum(y[1+k, i+k] for k in 0:N-i) <= N-i-1)
    end       


    @objective(m, Min, y[1, 1])

    # Start a chronometer
    start = time()

    # Solve the model

    nb_rep = Int64(0)

    optimize!(m)

    # Return:
    # 1 - true if an optimum is found
    isOptimal = termination_status(m) == MOI.OPTIMAL

    # 3 - Variables
    if primal_status(m) == MOI.FEASIBLE_POINT
        Y = Matrix{Int64}(undef,N,N)
        for i in 1:N
            for j in 1:N
                Y[i, j] = JuMP.value(y[i,j])
            end
        end
    else
        Y = Matrix{Int64}(zeros(N, N))
    end

    #################################################################
    #if Y[1,1]==0
    #    C=[[1, 1]]
    #    add_connexe(Y, 1, 1, C)
    #else
    #    C=[[1, 2]]
    #    add_connexe(Y, 1, 2, C)
    #end

    #isConnexe=is_connexe(Y, C)

    #while isOptimal && isConnexe==false && nb_rep<=100
    #    nb_rep+=1

        #Nouvelle contrainte qui permet de ne pas obtenir la même solution
    #    @constraint(m, y <= Y)

    #    optimize!(m)

        # Return:
        # 1 - true if an optimum is found
    #    isOptimal = termination_status(m) == MOI.OPTIMAL

        # 3 - Variables
    #    if primal_status(m) == MOI.FEASIBLE_POINT
    #        Y = Matrix{Int64}(undef,N,N)
    #        for i in 1:N
    #            for j in 1:N
    #                Y[i, j] = JuMP.value(y[i,j])
    #            end
    #        end
    #    else
    #        Y = Matrix{Int64}(zeros(N, N))
    #    end

    #    if Y[1,1]==0
    #        C=[[1, 1]]
    #        add_connexe(Y, 1, 1, C)
    #    else
    #        C=[[1, 2]]
    #        add_connexe(Y, 1, 2, C)
    #    end

    #    isConnexe=is_connexe(Y, C)

    #end
    #################################################################

    # 2 - the resolution time
    resTime = time()-start

    return isOptimal, resTime, Y #, nb_rep
end

function isPossible(i::Int64, j::Int64, y::Matrix{Int64})

    if i>1 && y[i-1,j]==1
        return false
    end
    if j>1 && y[i,j-1]==1
        return false
    end
    if i<N && y[i+1,j]==1
        return false
    end
    if j<N && y[i,j+1]==1
        return false
    end
    return true
end

function masquerCases(x::Matrix{Int64}, y::Matrix{Int64})

    solvable = true
    N = size(x, 1)

    # 3 cases d'affilées => masquer les extrémités
    for j in 1:N-2
        for i in 1:N
            if x[i,j]*(1-y[i,j]) == x[i,j+1]*(1-y[i,j+1]) && x[i,j]*(1-y[i,j]) == x[i,j+2]*(1-y[i,j+2])
                y[i,j] = 1
                y[i,j+2] = 1
            end
            if x[j,i]*(1-y[j,i]) == x[j+1,i]*(1-y[j+1,i]) && x[j,i]*(1-y[j,i]) == x[j+2,i]*(1-y[j+2,i])
                y[j,i] = 1
                y[j+2,i] = 1
            end
        end
    end

    # 2 cases d'affilées => une au hasard en vérifiant que c'est possible

    for j in 1:N-1
        for i in 1:N
            if x[i,j]*(1-y[i,j]) == x[i,j+1]*(1-y[i,j+1])

                pif = round(Int64, rand())
                if pif == 0
                    if isPossible(i,j, y)
                        Y = y
                        Y[i,j] = 1
                        if masquerCases(x, Y)
                            y=Y
                        else
                            Y[i,j] = 0
                            Y[i,j+1] = 1
                            if masquerCases(x, Y)
                                y=Y 
                            end
                        end
                        if impossible
                            solvable = false
                    end
                else
                    if isPossible(i,j+1, y)
                        Y = y
                        Y[i,j+1] = 1
                        if masquerCases(x, Y)
                            y=Y
                        else
                            Y[i,j+1] = 0
                            Y[i,j] = 1
                            if masquerCases(x, Y)
                                y=Y 
                            end
                        end
                    end
                end
            end
        end
    end

    # 2 nombres identiques dans la même lignes/colonnes
    #TODO

    return solvable
end
                
"""
Heuristically solve an instance
"""
function heuristicSolve(x::Matrix{Int64})
    N = size(x, 1)
    y = Matrix{Int64}(zeros(N, N))

    start = time()
    isOptimal = masquerCases(x, y)
    resTime = time() - start
        
    return isOptimal, resTime, y
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
        initMat = readInputFile(dataFolder * file)

        # TODO
        
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
                    isOptimal = cplexSolve(initMat)[1] 
                    resolutionTime = cplexSolve(initMat)[2]
                    
                    print(fout, "-- Resolution of " * file * "\n")

                    # If a solution is found, write it
                    if isOptimal
                        # TODO

                        solMat = cplexSolve(initMat)[3]
                        N = size(solMat, 1)
                                                
                        print(fout, "  ")
                        for j in 1:N 
                            print(fout, "---")
                        end
                        print(fout, "\n")
                        for i in 1:N
                            print(fout, "| ")
                            for j in 1:N 
                    
                                if solMat[i, j] == 0
                                    print(fout, " "*string(initMat[i, j])*" ")
                                else
                                    print(fout, " - ")
                                end
                                
                            end
                            print(fout, " |\n")
                        end
                        print(fout, "  ")
                        for j in 1:N 
                            print(fout, "---")
                        end
                        print(fout,"\n\n")
                    else
                        print(fout, "\nLa grille n'admet pas de solution\n\n")
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
                #println("In file resolution.jl, in method solveDataSet(), TODO: write the solution in fout") 
                close(fout)
            end


            # Display the results obtained with the method on the current instance
            #include(outputFile)
            println(resolutionMethod[methodId], " optimal: ", isOptimal)
            println(resolutionMethod[methodId], " time: " * string(round(solveTime, sigdigits=2)) * "s\n")
        end         
    end 
end
