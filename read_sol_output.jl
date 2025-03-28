use_invest_in_other_lines = true

use_old_sol = false

if use_invest_in_other_lines
    #We are allowed to invest in other internal NO/DE lines

    if use_old_sol
        #We use the solution stored by Ole and Håkon

        #Read results from CSV files
        d_df = CSV.read("Old_solution_output/outData_d.csv", DataFrame)
        f_df = CSV.read("Old_solution_output/outData_f.csv", DataFrame)
        g_df = CSV.read("Old_solution_output/outData_g.csv", DataFrame) #CORRESPONDS TO VARIABLE "q"
        x_df = CSV.read("Old_solution_output/outData_x.csv", DataFrame) 
        y_df = CSV.read("Old_solution_output/outData_y.csv", DataFrame)
        y_res_df = CSV.read("Old_solution_output/outData_yRes.csv", DataFrame) 
        z_df = CSV.read("Old_solution_output/outData_z.csv", DataFrame)

        #Note: a "2" means that it refers to the solution with no investment in the NO2-DE line.
        d_df2 = CSV.read("Old_solution_output/NoInvest_d.csv", DataFrame)
        f_df2 = CSV.read("Old_solution_output/NoInvest_f.csv", DataFrame)
        g_df2 = CSV.read("Old_solution_output/NoInvest_g.csv", DataFrame) #CORRESPONDS TO VARIABLE "q"
        x_df2 = CSV.read("Old_solution_output/NoInvest_x.csv", DataFrame) 
        y_df2 = CSV.read("Old_solution_output/NoInvest_y.csv", DataFrame)
        y_res_df2 = CSV.read("Old_solution_output/NoInvest_yRes.csv", DataFrame) 
        z_df2 = CSV.read("Old_solution_output/NoInvest_z.csv", DataFrame)
    else
        #We use the solution generated by Ruben in these julia files

        #Read results from CSV files
        d_df = CSV.read("New_solution_output/all_NO_DE_invest_d.csv", DataFrame)
        f_df = CSV.read("New_solution_output/all_NO_DE_invest_f.csv", DataFrame)
        g_df = CSV.read("New_solution_output/all_NO_DE_invest_q.csv", DataFrame) #NOTE: we use the name "g_df" to be consistent with old solution files
        x_df = CSV.read("New_solution_output/all_NO_DE_invest_x.csv", DataFrame) 
        y_df = CSV.read("New_solution_output/all_NO_DE_invest_y.csv", DataFrame)
        y_res_df = CSV.read("New_solution_output/all_NO_DE_invest_y_res.csv", DataFrame) 
        z_df = CSV.read("New_solution_output/all_NO_DE_invest_z.csv", DataFrame)

        #Note: a "2" means that it refers to the solution with no investment in the NO2-DE line.
        d_df2 = CSV.read("New_solution_output/NO_DE_except_cur_invest_d.csv", DataFrame)
        f_df2 = CSV.read("New_solution_output/NO_DE_except_cur_invest_f.csv", DataFrame)
        g_df2 = CSV.read("New_solution_output/NO_DE_except_cur_invest_q.csv", DataFrame) #NOTE: we use the name "g_df" to be consistent with old solution files
        x_df2 = CSV.read("New_solution_output/NO_DE_except_cur_invest_x.csv", DataFrame) 
        y_df2 = CSV.read("New_solution_output/NO_DE_except_cur_invest_y.csv", DataFrame)
        y_res_df2 = CSV.read("New_solution_output/NO_DE_except_cur_invest_y_res.csv", DataFrame) 
        z_df2 = CSV.read("New_solution_output/NO_DE_except_cur_invest_z.csv", DataFrame)

    end
    
else
    #We are NOT allowed to invest in other internal NO/DE lines

    #Read results from CSV files
    d_df = CSV.read("New_solution_output/only_cur_invest_d.csv", DataFrame)
    f_df = CSV.read("New_solution_output/only_cur_invest_f.csv", DataFrame)
    g_df = CSV.read("New_solution_output/only_cur_invest_q.csv", DataFrame) #NOTE: we use the name "g_df" to be consistent with old solution files
    x_df = CSV.read("New_solution_output/only_cur_invest_x.csv", DataFrame) 
    y_df = CSV.read("New_solution_output/only_cur_invest_y.csv", DataFrame)
    y_res_df = CSV.read("New_solution_output/only_cur_invest_y_res.csv", DataFrame) 
    z_df = CSV.read("New_solution_output/only_cur_invest_z.csv", DataFrame)

    #Note: a "2" means that it refers to the solution with no investment in the NO2-DE line.
    d_df2 = CSV.read("New_solution_output/zero_invest_d.csv", DataFrame)
    f_df2 = CSV.read("New_solution_output/zero_invest_f.csv", DataFrame)
    g_df2 = CSV.read("New_solution_output/zero_invest_q.csv", DataFrame) #NOTE: we use the name "g_df" to be consistent with old solution files
    x_df2 = CSV.read("New_solution_output/zero_invest_x.csv", DataFrame) 
    y_df2 = CSV.read("New_solution_output/zero_invest_y.csv", DataFrame)
    y_res_df2 = CSV.read("New_solution_output/zero_invest_y_res.csv", DataFrame) 
    z_df2 = CSV.read("New_solution_output/zero_invest_z.csv", DataFrame)
    
end



#transform dataframes into variables

#d
d = zeros(num_nodes, num_scenarios, num_periods)
d2 = zeros(num_nodes, num_scenarios, num_periods)
for s in 1:num_scenarios
    for n in 1:num_nodes
        for t in 1:num_periods
            cur_row = (s-1)*num_nodes*num_periods + (n-1)*num_periods + t
            d[n,s,t] = d_df.Val[cur_row]
            d2[n,s,t] = d_df2.Val[cur_row]
        end
    end
end
#f
f = zeros(num_lines, num_scenarios, num_periods)
f2 = zeros(num_lines, num_scenarios, num_periods)
for s in 1:num_scenarios
    for l in 1:num_lines
        for t in 1:num_periods
            cur_row = (s-1)*num_lines*num_periods + (l-1)*num_periods + t
            f[l,s,t] = f_df.Val[cur_row]
            f2[l,s,t] = f_df2.Val[cur_row]
        end
    end
end
#q
q = zeros(num_generators, num_scenarios, num_periods) #WILL BE FILLED BY "g"
q2 = zeros(num_generators, num_scenarios, num_periods) #WILL BE FILLED BY "g"
for s in 1:num_scenarios
    for g in 1:num_generators
        for t in 1:num_periods
            cur_row = (s-1)*num_generators*num_periods + (g-1)*num_periods + t
            q[g,s,t] = g_df.Val[cur_row]
            q2[g,s,t] = g_df2.Val[cur_row]
        end
    end
end
#x
x = x_df.Val
x2 = x_df2.Val
#y
y = y_df.Val
y2 = y_df2.Val
#y_res
y_res = zeros(num_technologies, num_nodes)
y_res2 = zeros(num_technologies, num_nodes)
for tech in 1:num_technologies
    for n in 1:num_nodes
        cur_row = (tech-1)*num_nodes + n
        y_res[tech,n] = y_res_df.Val[cur_row]
        y_res2[tech,n] = y_res_df2.Val[cur_row]
    end
end
#objective (net total welfare)
objective = z_df.Val[1]
objective2 = z_df2.Val[1]

