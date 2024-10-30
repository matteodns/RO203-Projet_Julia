# This file contains methods to generate a data set of instances (i.e., sudoku grids)
include("io.jl")

function valPossible(val::Int64, x::Matrix{Int64}, i::Int64, j::Int64)

    N = size(x, 1)
    M = size(x, 2)

    #Pas plus de M/2-1 égales à val au début de la lignes
    nb_ligne = Int64(0)
    for k in 1:i-1
        nb_ligne = 0
        if x[k,j] == val
            nb_ligne += 1
        end
    end
    if nb_ligne >= N/2
        return false
    end

    #Pas plus de N/2-1 égales à val au début de la colonne
    nb_col = Int64(0)
    for k in 1:j-1
        nb_col = 0
        if x[i,k] == val
            nb_col += 1
        end
    end
    if nb_col >= M/2
        return false
    end

    #Les deux à gauches ne doivent pas être tous les deux égaux à val
    if j >= 3 && x[i,1] == val && x[i,2] == val
        return false
    end

    #Les deux en haut ne doivent pas être tous les deux égaux à val
    if i >= 3 && x[1,j] == val && x[2,j] == val
        return false
    end

    return true
end

"""
Generate an N*M grid with a given density

Argument
- N : number of lines (must be even)
- M : number of colons (must be even)
- density: percentage in [0, 1] of initial values in the grid
"""
function generateInstance(N::Int64, M::Int64,  density::Float64, filename::String)

    # TODO

    # On créé d'abord la matrice (plus simple pour les)

    x = Matrix{Int64}(undef, N, M)
    newVal = Int64(100)
    for i in 1:N
        for j in 1:M
            x[i, j] = 100
            r1 = rand()
            if r1 <= density
                newVal = round(Int64, rand()) #0 ou 1
                if valPossible(newVal, x, i, j)
                    x[i, j] = newVal
                end
            end
        end
    end

    # On créé le fichier txt à partir de la matrice

    open(filename, "w") do file
        for i in 1:N
            for j in 1:M-1
                if x[i, j] == 0
                    write(file, "0,")
                end
                if x[i, j] == 1
                    write(file, "1,")
                end
                if x[i, j] == 100
                    write(file, " ,")
                end
            end
                if x[i, M] == 0
                    write(file, "0\n")
                end
                if x[i, M] == 1
                    write(file, "1\n")
                end
                if x[i, M] == 100
                    write(file, " \n")
                end
        end
    end    
end

"""
Generate all the instances

Remark: a grid is generated only if the corresponding output file does not already exist
"""
function generateDataSet(nb::Int64, N::Int64, M::Int64, density::Float64, filenames::String)

    # TODO  
    for i in 1:nb

        generateInstance(N, M, density, "./data/" * filenames * "_" * string(i) * ".txt")
    end    
end



