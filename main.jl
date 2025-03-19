#PACKAGES
using Statistics
import XLSX
using CSV
using DataFrames




#Set working directory
cd("//home.ansatt.ntnu.no/egbertrv/Documents/Research/Transmission expansion/Code/TEP_Julia")

#-------------------------------------------------------------------------------------------------

#Read instance data
include("read_data.jl")

#Make/solve optimization model
solve_model = false
if solve_model
    include("opt_model.jl")
end


#Analyze the results
analyze_results = true
if analyze_results
    #Read solution output
    include("read_sol_output.jl")

    #Process results
    include("process_results.jl")

    #Compute correlations
    include("compute_correlations.jl")

    compensate_only_NO_DE = true
    if compensate_only_NO_DE    
        #Define compensation mechanisms
        include("compensation_mechanisms.jl")

        #Compute performance measures
        include("performance_measures.jl")
    else #compensate larger coalition
        #Define compensation mechanisms
        include("compensation_mechanisms_coalition.jl")

        #Compute performance measures
        include("performance_measures_coalition.jl")
    end
end

#End program
print("Program finished.")


