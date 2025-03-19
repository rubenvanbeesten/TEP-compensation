using JuMP
using Gurobi
using TickTock


#Clear model elements for reuse (necessary if we solve multiple model versions in a loop)

m = nothing
f = nothing
x = nothing
d = nothing
q = nothing
y = nothing
y_res = nothing

########### FOR TESTING PURPOSES ONLY: ONE SCENARIO ##########################

#num_scenarios = 1
#for s in 1:num_scenarios
#    prob[s] = 1/num_scenarios
#end


##############################################################################

#(dis)allow investment in other internal NO-DE lines
invest_in_other_lines = true
#(dis)allow investment in cur_line:
invest_in_cur_line = false

println("invest_in_cur_line = ", invest_in_cur_line)

#model object
m = Model(Gurobi.Optimizer)

#TSO variables
@variable(m, f[1:num_lines, 1:num_scenarios, 1:num_periods]) #flow on each line
@variable(m, x[1:num_lines] >= 0) #cap investment in each line
#@variable(m, theta[1:num_scenarios, 1:num_nodes, 1:num_periods]) #NOT USED
#@variable(m, h[1:num_scenarios, 1:num_nodes, 1:num_periods] >= 0) #NOT USED
#@variable(m, q[1:num_scenarios, 1:num_generators, 1:num_nodes, 1:num_periods] >= 0) #NOT USED

#fix some (or all except cur_line) x variables to zero
for l in 1:num_lines
    #fix all lines outside of NO-DE area to zero
    if NO_DE_lines[l] == 0
        fix(x[l], 0; force=true)
    elseif !invest_in_other_lines
        #depending on boolean, fix all except current line to zero
        if l != cur_line
            fix(x[l], 0; force=true)
        end
    end
    #forbid investment in cur_line if boolean says so
    if l == cur_line
        if !invest_in_cur_line
            fix(x[l], 0; force=true)
        end
    end
end


#Consumer variables
@variable(m, d[1:num_nodes, 1:num_scenarios, 1:num_periods] >= 0) #demand from each node

#Producer variables
@variable(m, q[1:num_generators, 1:num_scenarios, 1:num_periods] >= 0)  #quantity of generation NOTE: IS "g" in GAMS
@variable(m, y[1:num_generators] >= 0) #investment in generators
@variable(m, y_res[1:num_technologies, 1:num_nodes] >= 0) #investment in renewable generators

#Overview of variables with indices: (NOTE: A LOT IS DIFFERENT FROM GAMS. ESPECIALLY THE ORDER OF INDICES)
# f[l,s,t]
# x[l]
# d[n,s,t]
# q[g,s,t]
# y[g]
# y_res[tech,n]

#general order of indices: tech,n,g,s,seas,t (may be deviations from this)


#Objective
@objective(m, Max, #maximize total welfare:
    sum( prob[s]*( 0.5*dem_A[n,s,t]*d[n,s,t] + dem_B[n,s,t])*d[n,s,t] for  n in 1:num_nodes, s in 1:num_scenarios, t in 1:num_periods) #area under demand curve
    - sum( prob[s]*C_gen_B[g,t]*q[g,s,t]  for g in 1:num_generators, s in 1:num_scenarios, t in 1:num_periods ) #production cost 
    - sum( C_I_gen[g]*y[g] for g in 1:num_generators ) #investment cost in generators
    - sum( C_I_res[tech,n]*y_res[tech,n] for tech in 1:num_technologies, n in 1:num_nodes ) #investment cost in renewables
    - sum( C_I_line[l]*x[l] for l in 1:num_lines ) #investment cost in lines
)

#Constraints (in order of article formulation)

#Generator capacity
@constraint(m, gen_cap[g in 1:num_generators, s in 1:num_scenarios, t in 1:num_periods], 
    q[g,s,t] <= g_up[g] + y[g]
)

#Generator capacity over season
@constraint(m, seas_gen_cap[g in 1:num_generators, s in 1:num_scenarios, seas in 1:num_seasons], 
    sum(q[g,s,t] for t in season_periods[seas]) <= prod_lim[g,s,seas]  
) 

#Market clearing
@constraint(m, market_clearing[n in 1:num_nodes, s in 1:num_scenarios, t in 1:num_periods], 
    d[n,s,t] + sum( A[n,l]*f[l,s,t] for l in 1:num_lines) #demand plus net outflow
    == sum( q[g,s,t] for g in 1:num_generators if gen_connect[g,n] == 1 )  #production from conventional generators 
    + sum( (pres[tech,n] + y_res[tech,n])*res[tech,n,s,t] for tech in 1:num_technologies)   #production from renewables
)

#Flow capacity: forward
@constraint(m, flow_cap_forward[l in 1:num_lines, s in 1:num_scenarios, t in 1:num_periods],
    f[l,s,t] <= l_up[l] + x[l]
)

#Flow capacity: backward
@constraint(m, flow_cap_backward[l in 1:num_lines, s in 1:num_scenarios, t in 1:num_periods],
    -f[l,s,t] <= l_up[l] + x[l]
)

println("Done reading the model")

#Solve the model
solution = optimize!(m)

solution_summary(m)

#store objective value
obj_val = objective_value(m)

#store solution (reuse variable names. This )
f = value.(f)
x = value.(x)
d = value.(d)
q = value.(q)
y = value.(y)
y_res = value.(y_res)

#delete the model object 
m = nothing

##########################

#write solution to file

#first create data DataFrames
f_df = DataFrame()
x_df = DataFrame()
d_df = DataFrame()
q_df = DataFrame()
y_df = DataFrame()
y_res_df = DataFrame()


#f[l,s,t] -> f[s,l,t]
dim_f = num_scenarios * num_lines * num_periods
f_df.s = zeros(dim_f)
f_df.l = zeros(dim_f)
f_df.t = zeros(dim_f)
f_df.Val = zeros(dim_f)
for s in 1:num_scenarios
    for l in 1:num_lines
        for t in 1:num_periods
            cur_row = (s-1)*(num_lines * num_periods) + (l-1)*num_periods + t
            f_df.s[cur_row] = s
            f_df.l[cur_row] = l
            f_df.t[cur_row] = t
            f_df.Val[cur_row] = f[l,s,t]
        end
    end
end

#x[l]
dim_x = num_lines
x_df.l = zeros(dim_x)
x_df.Val = zeros(dim_x)
for l in 1:num_lines
    cur_row = l
    x_df.l[cur_row] = l
    x_df.Val[cur_row] = x[l]
end

# d[n,s,t] -> d[s,n,t]
dim_d = num_scenarios * num_nodes * num_periods
d_df.s = zeros(dim_d)
d_df.n = zeros(dim_d)
d_df.t = zeros(dim_d)
d_df.Val = zeros(dim_d)
for s in 1:num_scenarios
    for n in 1:num_nodes
        for t in 1:num_periods
            cur_row = (s-1)*(num_nodes * num_periods) + (n-1)*num_periods + t
            d_df.s[cur_row] = s
            d_df.n[cur_row] = n
            d_df.t[cur_row] = t
            d_df.Val[cur_row] = d[n,s,t]
        end
    end
end

# q[g,s,t] -> q[s,g,t]
dim_q = num_scenarios * num_generators * num_periods
q_df.s = zeros(dim_q)
q_df.g = zeros(dim_q)
q_df.t = zeros(dim_q)
q_df.Val = zeros(dim_q)
for s in 1:num_scenarios
    for g in 1:num_generators
        for t in 1:num_periods
            cur_row = (s-1)*(num_generators * num_periods) + (g-1)*num_periods + t
            q_df.s[cur_row] = s
            q_df.g[cur_row] = g
            q_df.t[cur_row] = t
            q_df.Val[cur_row] = q[g,s,t]
        end
    end
end

# y[g]
dim_y = num_generators
y_df.g = zeros(dim_y)
y_df.Val = zeros(dim_y)
for g in 1:num_generators
    cur_row = g
    y_df.g[cur_row] = g
    y_df.Val[cur_row] = y[g]
end

# y_res[tech,n]
dim_y_res = num_technologies * num_nodes
y_res_df.tech = zeros(dim_y_res)
y_res_df.n = zeros(dim_y_res)
y_res_df.Val = zeros(dim_y_res)
for tech in 1:num_technologies
    for n in 1:num_nodes
        cur_row = (tech-1)*num_nodes + n
        y_res_df.tech[cur_row] = tech
        y_res_df.n[cur_row] = n
        y_res_df.Val[cur_row] = y_res[tech,n]
    end
end

#z (opt. objective value)
z_df = DataFrame()
z_df.Val = [obj_val]

#create path string for storing the results
path_string = pwd() * "\\New_solution_output"

if invest_in_other_lines
    #we can invest in other NO/DE lines
    if invest_in_cur_line
        path_string = path_string * "\\all_NO_DE_invest"
    else
        path_string = path_string * "\\NO_DE_except_cur_invest"
    end
else
    #no investment in  other NO/DE lines    
    if invest_in_cur_line 
        path_string = path_string * "\\only_cur_invest"
    else
        path_string = path_string * "\\zero_invest"
    end
end

# Write to CSV files
CSV.write(path_string * "_f" * ".csv", f_df)
CSV.write(path_string * "_x" * ".csv", x_df)
CSV.write(path_string * "_d" * ".csv", d_df)
CSV.write(path_string * "_q" * ".csv", q_df) #NOTE: this is inconsistent with old results. There they used variable name "g"
CSV.write(path_string * "_y" * ".csv", y_df)
CSV.write(path_string * "_y_res" * ".csv", y_res_df)
CSV.write(path_string * "_z" * ".csv", z_df)


