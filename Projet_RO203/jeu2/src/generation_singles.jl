# This file contains methods to generate a data set of instances (i.e., sudoku grids)
include("io_singles.jl")

"""
Generate an n*n grid with a given density

Argument
- n: size of the grid
- density: percentage in [0, 1] of initial values in the grid
"""
function generateInstance(N::Int64, filename::String)

    # TODO
    
    open(filename, "w") do file
        for i in 1:N
            for j in 1:N-1 
                nb = ceil(Int, rand()*N)
                
                write(file, string(nb)*",")
            end
            nb = ceil(Int, rand()*N)
            write(file, string(nb)*"\n")
        end
    end
end 

"""
Generate all the instances

Remark: a grid is generated only if the corresponding output file does not already exist
"""
function generateDataSet(nb::Int64, N::Int64, filenames::String)

    # TODO

    for i in 1:nb  

        chemin_data = joinpath(pwd(), "data")
        chemin_fichier = joinpath(chemin_data,  filenames * "_" * string(i) * ".txt")

        generateInstance(N, "./data/" * filenames * "_" * string(i) * ".txt")
    end
end



