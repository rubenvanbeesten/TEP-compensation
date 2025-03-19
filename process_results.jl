
#Prices:

#Compute prices
price = dem_A .* d .+ dem_B
price2 = dem_A .* d2 .+ dem_B

#prices in NO2 and DE (connected to the new line)
NO2_price = price[node_dict["NO2"],:,:]
DE_price = price[node_dict["DE"],:,:]


#Congestion:

line_congested = zeros(Bool, num_lines, num_scenarios, num_periods)
for l in 1:num_lines
    for s in 1:num_scenarios
        for t in 1:num_periods
            if (f[l,s,t] ≈ l_up[l] + x[l]) || (-f[l,s,t] ≈ l_up[l] + x[l])
                line_congested[l,s,t] = true
            end
        end
    end
end
cur_line_congested = line_congested[line_NO2_DE,:,:]
cur_line_uncongested = .! cur_line_congested
cur_line_congested_vec = vec(cur_line_congested)
cur_line_uncongested_vec = vec(cur_line_uncongested)


#Welfare parts:

#Conventional producers

#revenue for each generator per s,t
p_revenue = zeros(num_generators, num_scenarios, num_periods)
p_revenue2 = zeros(num_generators, num_scenarios, num_periods)
for g in 1:num_generators
    for s in 1:num_scenarios
        for t in 1:num_periods
            p_revenue[g,s,t] = (price[gen_to_node[g],s,t] - C_gen_B[g,t])*q[g,s,t]
            p_revenue2[g,s,t] = (price2[gen_to_node[g],s,t] - C_gen_B[g,t])*q2[g,s,t]
        end
    end
end
#revenue for each node per s,t
node_revenue = zeros(num_nodes, num_scenarios, num_periods)
node_revenue2 = zeros(num_nodes, num_scenarios, num_periods)
for n in 1:num_nodes
    for s in 1:num_scenarios
        for t in 1:num_periods
            node_revenue[n,s,t] = sum(p_revenue[g,s,t] for g in 1:num_generators if gen_connect[g,n] == 1)
            node_revenue2[n,s,t] = sum(p_revenue2[g,s,t] for g in 1:num_generators if gen_connect[g,n] == 1)
        end
    end
end
#expected revenue for each node per period per t
exp_node_revenue = zeros(num_nodes, num_periods)
exp_node_revenue2 = zeros(num_nodes, num_periods)
for n in 1:num_nodes
    for t in 1:num_periods
        exp_node_revenue[n,t] = sum(prob[s]*node_revenue[n,s,t] for s in 1:num_scenarios)
        exp_node_revenue2[n,t] = sum(prob[s]*node_revenue2[n,s,t] for s in 1:num_scenarios)
    end
end
#total revenue for each node over entire horizon per s
total_node_revenue = zeros(num_nodes, num_scenarios)
total_node_revenue2 = zeros(num_nodes, num_scenarios)
for n in 1:num_nodes
    for s in 1:num_scenarios
        total_node_revenue[n,s] = sum(node_revenue[n,s,t] for t in 1:num_periods)
        total_node_revenue2[n,s] = sum(node_revenue2[n,s,t] for t in 1:num_periods)
    end
end
#expected total revenue for each node over all periods
exp_total_node_revenue = zeros(num_nodes)
exp_total_node_revenue2 = zeros(num_nodes)
for n in 1:num_nodes
    exp_total_node_revenue[n] = sum(exp_node_revenue[n,t] for t in 1:num_periods)
    exp_total_node_revenue2[n] = sum(exp_node_revenue2[n,t] for t in 1:num_periods)
end
#investment cost per g
p_inv_cost = zeros(num_generators)
p_inv_cost2 = zeros(num_generators)
for g in 1:num_generators
    p_inv_cost[g] = C_I_gen[g]*y[g]
    p_inv_cost2[g] = C_I_gen[g]*y2[g]
end
#investment cost per n
node_inv_cost = zeros(num_nodes)
node_inv_cost2 = zeros(num_nodes)
for n in 1:num_nodes
    node_inv_cost[n] = sum(p_inv_cost[g] for g in 1:num_generators if gen_connect[g,n] == 1)
    node_inv_cost2[n] = sum(p_inv_cost2[g] for g in 1:num_generators if gen_connect[g,n] == 1)
end
#total node profit per s (these are the consumer surplus contributions)
node_profit = zeros(num_nodes, num_scenarios)
node_profit2 = zeros(num_nodes, num_scenarios)
for n in 1:num_nodes
    for s in 1:num_scenarios
        node_profit[n,s] = total_node_revenue[n,s] - node_inv_cost[n]
        node_profit2[n,s] = total_node_revenue2[n,s] - node_inv_cost2[n]
    end
end
#expected total node profit over entire horizon (expected consumer surplus contribution)
exp_node_profit = zeros(num_nodes)
exp_node_profit2 = zeros(num_nodes)
for n in 1:num_nodes
    exp_node_profit[n] = exp_total_node_revenue[n] - node_inv_cost[n]
    exp_node_profit2[n] = exp_total_node_revenue2[n] - node_inv_cost2[n]
end
#overall expected profit
overall_exp_profit = sum(exp_node_profit[n] for n in 1:num_nodes)
overall_exp_profit2 = sum(exp_node_profit2[n] for n in 1:num_nodes)


#Renewable producers

#revenue for each tech/node combination per s,t
p_res_revenue = zeros(num_technologies, num_nodes, num_scenarios, num_periods)
p_res_revenue2 = zeros(num_technologies, num_nodes, num_scenarios, num_periods)
for tech in 1:num_technologies
    for n in 1:num_nodes
        for s in 1:num_scenarios
            for t in 1:num_periods
                p_res_revenue[tech,n,s,t] = price[n,s,t] * ( (pres[tech,n] + y_res[tech,n])*res[tech,n,s,t] )
                p_res_revenue2[tech,n,s,t] = price2[n,s,t] * ( (pres[tech,n] + y_res2[tech,n])*res[tech,n,s,t] )
            end
        end
    end
end
#revenue for each node per s,t
node_res_revenue = zeros(num_nodes, num_scenarios, num_periods)
node_res_revenue2 = zeros(num_nodes, num_scenarios, num_periods)
for n in 1:num_nodes
    for s in 1:num_scenarios
        for t in 1:num_periods
            node_res_revenue[n,s,t] = sum(p_res_revenue[tech,n,s,t] for tech in 1:num_technologies)
            node_res_revenue2[n,s,t] = sum(p_res_revenue2[tech,n,s,t] for tech in 1:num_technologies)
        end
    end
end
#expected revenue for each node per t
node_res_exp_revenue = zeros(num_nodes, num_periods)
node_res_exp_revenue2 = zeros(num_nodes, num_periods)
for n in 1:num_nodes
    for t in 1:num_periods
        node_res_exp_revenue[n,t] = sum(prob[s]*node_res_revenue[n,s,t] for s in 1:num_scenarios)
        node_res_exp_revenue2[n,t] = sum(prob[s]*node_res_revenue2[n,s,t] for s in 1:num_scenarios)
    end
end
#total revenue for each node per over entire horizon for each s
node_res_total_revenue = zeros(num_nodes, num_scenarios)
node_res_total_revenue2 = zeros(num_nodes, num_scenarios)
for n in 1:num_nodes
    for s in 1:num_scenarios
        node_res_total_revenue[n,s] = sum(node_res_revenue[n,s,t] for t in 1:num_periods)
        node_res_total_revenue2[n,s] = sum(node_res_revenue2[n,s,t] for t in 1:num_periods)        
    end
end
#expected total revenue for each node over entire horizon
node_res_total_exp_revenue = zeros(num_nodes)
node_res_total_exp_revenue2 = zeros(num_nodes)
for n in 1:num_nodes
    node_res_total_exp_revenue[n] = sum(node_res_exp_revenue[n,t] for t in 1:num_periods)
    node_res_total_exp_revenue2[n] = sum(node_res_exp_revenue2[n,t] for t in 1:num_periods)
end

#investment cost per renewable generator
p_res_inv_cost = zeros(num_technologies, num_nodes)
p_res_inv_cost2 = zeros(num_technologies, num_nodes)
for tech in 1:num_technologies
    for n in 1:num_nodes
        p_res_inv_cost[tech,n] = C_I_res[tech,n]*y_res[tech,n]
        p_res_inv_cost2[tech,n] = C_I_res[tech,n]*y_res2[tech,n]
    end
end
#investment cost per node
node_res_inv_cost = zeros(num_nodes)
node_res_inv_cost2 = zeros(num_nodes)
for n in 1:num_nodes
    node_res_inv_cost[n] = sum(p_res_inv_cost[tech,n] for tech in 1:num_technologies)
    node_res_inv_cost2[n] = sum(p_res_inv_cost2[tech,n] for tech in 1:num_technologies)
end
#total node profit per s
node_res_profit = zeros(num_nodes, num_scenarios)
node_res_profit2 = zeros(num_nodes, num_scenarios)
for n in 1:num_nodes
    for s in 1:num_scenarios
        node_res_profit[n,s] = node_res_total_revenue[n,s] - node_res_inv_cost[n]
        node_res_profit2[n,s] = node_res_total_revenue2[n,s] - node_res_inv_cost2[n]
    end
end
#total expected node profit
node_res_exp_profit = zeros(num_nodes)
node_res_exp_profit2 = zeros(num_nodes)
for n in 1:num_nodes
    node_res_exp_profit[n] = sum(prob[s]*node_res_profit[n,s] for s in 1:num_scenarios)
    node_res_exp_profit2[n] = sum(prob[s]*node_res_profit2[n,s] for s in 1:num_scenarios)
end
#overall expected profit
overall_res_exp_profit = sum(node_res_exp_profit[n] for n in 1:num_nodes)
overall_res_exp_profit2 = sum(node_res_exp_profit2[n] for n in 1:num_nodes)


#Conventional and renewable producers combined

#total expected node profit
node_combined_exp_profit = zeros(num_nodes)
node_combined_exp_profit2 = zeros(num_nodes)
for n in 1:num_nodes
    node_combined_exp_profit[n] = exp_node_profit[n] + node_res_exp_profit[n]
    node_combined_exp_profit2[n] = exp_node_profit2[n] + node_res_exp_profit2[n]
end

#aggregate for NO and DE
NO_combined_exp_profit = sum(node_combined_exp_profit[n] for n in NO_nodes)
NO_combined_exp_profit2 = sum(node_combined_exp_profit2[n] for n in NO_nodes)
NO_combined_exp_profit_delta = NO_combined_exp_profit - NO_combined_exp_profit2
DE_combined_exp_profit = sum(node_combined_exp_profit[n] for n in DE_nodes)
DE_combined_exp_profit2 = sum(node_combined_exp_profit2[n] for n in DE_nodes)
DE_combined_exp_profit_delta = DE_combined_exp_profit - DE_combined_exp_profit2

#Consumers

#consumer surplus
node_CS = zeros(num_nodes, num_scenarios, num_periods)
node_CS2 = zeros(num_nodes, num_scenarios, num_periods)
for n in 1:num_nodes
    for s in 1:num_scenarios
        for t in 1:num_periods
            node_CS[n,s,t] = ( 0.5 * dem_A[n,s,t]*d[n,s,t] + dem_B[n,s,t] - price[n,s,t] ) * d[n,s,t]
            node_CS2[n,s,t] = ( 0.5 * dem_A[n,s,t]*d2[n,s,t] + dem_B[n,s,t] - price2[n,s,t] ) * d2[n,s,t]
        end
    end
end
#total node CS over all periods
node_total_CS = zeros(num_nodes, num_scenarios)
node_total_CS2 = zeros(num_nodes, num_scenarios)
for n in 1:num_nodes
    for s in 1:num_scenarios
        node_total_CS[n,s] = sum(node_CS[n,s,t] for t in 1:num_periods)
        node_total_CS2[n,s] = sum(node_CS2[n,s,t] for t in 1:num_periods)
    end
end
#expected total node CS 
node_exp_total_CS = zeros(num_nodes)
node_exp_total_CS2 = zeros(num_nodes)
for n in 1:num_nodes
    node_exp_total_CS[n] = sum(prob[s]*node_total_CS[n,s] for s in 1:num_scenarios)
    node_exp_total_CS2[n] = sum(prob[s]*node_total_CS2[n,s] for s in 1:num_scenarios)
end
#overall expected total CS
overall_exp_CS = sum(node_exp_total_CS[n] for n in 1:num_nodes)
overall_exp_CS2 = sum(node_exp_total_CS2[n] for n in 1:num_nodes)

#aggregate for the countries
NO_exp_total_CS = sum(node_exp_total_CS[n] for n in NO_nodes)
NO_exp_total_CS2 = sum(node_exp_total_CS2[n] for n in NO_nodes)
NO_exp_total_CS_delta = NO_exp_total_CS - NO_exp_total_CS2
DE_exp_total_CS = sum(node_exp_total_CS[n] for n in DE_nodes)
DE_exp_total_CS2 = sum(node_exp_total_CS2[n] for n in DE_nodes)
DE_exp_total_CS_delta = DE_exp_total_CS - DE_exp_total_CS2




#TSO

#line congestion rent per s, t
line_CR = zeros(num_lines, num_scenarios, num_periods)
line_CR2 = zeros(num_lines, num_scenarios, num_periods)
for l in 1:num_lines
    for s in 1:num_scenarios
        for t in 1:num_periods
            line_CR[l,s,t] = f[l,s,t] * ( price[line_dest[l],s,t] - price[line_orig[l],s,t] )
            line_CR2[l,s,t] = f2[l,s,t] * ( price2[line_dest[l],s,t] - price2[line_orig[l],s,t] )
        end
    end
end
#line total congestion rent per s
line_total_CR = zeros(num_lines, num_scenarios)
line_total_CR2 = zeros(num_lines, num_scenarios)
for l in 1:num_lines
    for s in 1:num_scenarios
        line_total_CR[l,s] = sum(line_CR[l,s,t] for t in 1:num_periods)
        line_total_CR2[l,s] = sum(line_CR2[l,s,t] for t in 1:num_periods)
    end
end
#line expected total congestion rent
line_exp_total_CR = zeros(num_lines)
line_exp_total_CR2 = zeros(num_lines)
for l in 1:num_lines
    line_exp_total_CR[l] = sum(prob[s]*line_total_CR[l,s] for s in 1:num_scenarios)
    line_exp_total_CR2[l] = sum(prob[s]*line_total_CR2[l,s] for s in 1:num_scenarios)
end
overall_exp_CR = sum(line_exp_total_CR[l] for l in 1:num_lines)
overall_exp_CR2 = sum(line_exp_total_CR2[l] for l in 1:num_lines)


#CR per node
node_CR = zeros(num_nodes, num_scenarios, num_periods)
node_CR2 = zeros(num_nodes, num_scenarios, num_periods)
for n in 1:num_nodes
    for l in 1:num_lines
        if abs_line_connect[n,l] == 1
            for s in 1:num_scenarios
                for t in 1:num_periods
                    node_CR[n,s,t] += 0.5 * line_CR[l,s,t]
                    node_CR2[n,s,t] += 0.5 * line_CR2[l,s,t]
                end
            end
        end
    end
end

node_total_CR = zeros(num_nodes, num_scenarios)
node_total_CR2 = zeros(num_nodes, num_scenarios)
for n in 1:num_nodes
    for s in 1:num_scenarios
        node_total_CR[n,s] = sum(node_CR[n,s,:])
        node_total_CR2[n,s] = sum(node_CR2[n,s,:])
    end
end

node_exp_total_CR = zeros(num_nodes)
node_exp_total_CR2 = zeros(num_nodes)
for n in 1:num_nodes
    node_exp_total_CR[n] = sum(prob[s]*node_total_CR[n,s] for s in 1:num_scenarios)
    node_exp_total_CR2[n] = sum(prob[s]*node_total_CR2[n,s] for s in 1:num_scenarios)
end

NO_CR = zeros(num_scenarios, num_periods)
NO_CR2 = zeros(num_scenarios, num_periods)
DE_CR = zeros(num_scenarios, num_periods)
DE_CR2 = zeros(num_scenarios, num_periods)
for s in 1:num_scenarios
    for t in 1:num_periods
        NO_CR[s,t] = sum(node_CR[NO_nodes,s,t])
        NO_CR2[s,t] = sum(node_CR2[NO_nodes,s,t])
        DE_CR[s,t] = sum(node_CR[DE_nodes,s,t])
        DE_CR2[s,t] = sum(node_CR2[DE_nodes,s,t])
    end
end

NO_total_CR = zeros(num_scenarios)
NO_total_CR2 = zeros(num_scenarios)
DE_total_CR = zeros(num_scenarios)
DE_total_CR2 = zeros(num_scenarios)
for s in 1:num_scenarios
    for t in 1:num_periods
        NO_total_CR[s] = sum(NO_CR[s,t] for t in 1:num_periods)
        NO_total_CR2[s] = sum(NO_CR2[s,t] for t in 1:num_periods)
        DE_total_CR[s] = sum(DE_CR[s,t] for t in 1:num_periods)
        DE_total_CR2[s] = sum(DE_CR2[s,t] for t in 1:num_periods)
    end
end

NO_total_CR_delta = NO_total_CR .- NO_total_CR2
DE_total_CR_delta = DE_total_CR .- DE_total_CR2


#TSO investments

#line investment
line_inv_cost = zeros(num_lines)
line_inv_cost2 = zeros(num_lines)
for l in 1:num_lines
    line_inv_cost[l] = x[l] * C_I_line[l]
    line_inv_cost2[l] = x2[l] * C_I_line[l]
end
#total line investment
overall_line_inv_cost = sum(line_inv_cost[l] for l in 1:num_lines)
overall_line_inv_cost2 = sum(line_inv_cost2[l] for l in 1:num_lines)

#node line investments (how much each nodes contributes to the line investments)
node_line_inv_cost = zeros(num_nodes)
node_line_inv_cost2 = zeros(num_nodes)
for n in 1:num_nodes
    for l in 1:num_lines
        if abs_line_connect[n,l] == 1
            node_line_inv_cost[n] += 0.5 * line_inv_cost[l]
            node_line_inv_cost2[n] += 0.5 * line_inv_cost2[l]
        end
    end
end

#net expected profit per line
line_net_profit = zeros(num_lines)
line_net_profit2 = zeros(num_lines)
for l in 1:num_lines
    line_net_profit[l] = line_exp_total_CR[l] - line_inv_cost[l]
    line_net_profit2[l] = line_exp_total_CR2[l] - line_inv_cost2[l]
end


#Country welfares

#node gross current welfare per s, T #NOTE: THIS IGNORES INVESTMENT COST OF PRODUCERS AND GOVERNMENT
node_gross_cur_welfare = zeros(num_nodes, num_scenarios, num_periods)
node_gross_cur_welfare2 = zeros(num_nodes, num_scenarios, num_periods)
for n in 1:num_nodes
    for s in 1:num_scenarios
        for t in 1:num_periods
            node_gross_cur_welfare[n,s,t] = node_revenue[n,s,t] + node_res_revenue[n,s,t] + node_CS[n,s,t] + node_CR[n,s,t]
            node_gross_cur_welfare2[n,s,t] = node_revenue2[n,s,t] + node_res_revenue2[n,s,t] + node_CS2[n,s,t] + node_CR2[n,s,t]
        end
    end
end
#Norway gross current welfare per s, t 
NO_gross_cur_welfare = zeros(num_scenarios, num_periods)
NO_gross_cur_welfare2 = zeros(num_scenarios, num_periods)
for s in 1:num_scenarios
    for t in 1:num_periods
        NO_gross_cur_welfare[s,t] = sum(node_gross_cur_welfare[n,s,t] for n in NO_nodes)
        NO_gross_cur_welfare2[s,t] = sum(node_gross_cur_welfare2[n,s,t] for n in NO_nodes)
    end
end
#Germany gross current welfare per s, t 
DE_gross_cur_welfare = zeros(num_scenarios, num_periods)
DE_gross_cur_welfare2 = zeros(num_scenarios, num_periods)
for s in 1:num_scenarios
    for t in 1:num_periods
        DE_gross_cur_welfare[s,t] = sum(node_gross_cur_welfare[n,s,t] for n in DE_nodes)
        DE_gross_cur_welfare2[s,t] = sum(node_gross_cur_welfare2[n,s,t] for n in DE_nodes)
    end
end
#node gross total welfare per s
node_gross_welfare = zeros(num_nodes, num_scenarios)
node_gross_welfare2 = zeros(num_nodes, num_scenarios)
for n in 1:num_nodes
    for s in 1:num_scenarios
        node_gross_welfare[n,s] = sum(node_gross_cur_welfare[n,s,t] for t in 1:num_periods)
        node_gross_welfare2[n,s] = sum(node_gross_cur_welfare2[n,s,t] for t in 1:num_periods)
    end
end
#node net total welfare per s
node_welfare = zeros(num_nodes, num_scenarios)
node_welfare2 = zeros(num_nodes, num_scenarios)
for n in 1:num_nodes
    for s in 1:num_scenarios
        node_welfare[n,s] = node_gross_welfare[n,s] - node_inv_cost[n] - node_res_inv_cost[n] - node_line_inv_cost[n]
        node_welfare2[n,s] = node_gross_welfare2[n,s] - node_inv_cost2[n] - node_res_inv_cost2[n] - node_line_inv_cost2[n]
    end
end


#Norway net total welfare per s
NO_welfare = zeros(num_scenarios)
NO_welfare2 = zeros(num_scenarios)
for s in 1:num_scenarios
    NO_welfare[s] = sum(node_welfare[n,s] for n in NO_nodes)
    NO_welfare2[s] = sum(node_welfare2[n,s] for n in NO_nodes)
end
#Germany net total welfare per s 
DE_welfare = zeros(num_scenarios)
DE_welfare2 = zeros(num_scenarios)
for s in 1:num_scenarios
    DE_welfare[s] = sum(node_welfare[n,s] for n in DE_nodes)
    DE_welfare2[s] = sum(node_welfare2[n,s] for n in DE_nodes)
end
#Austria net total welfare per s
AT_welfare = zeros(num_scenarios)
AT_welfare2 = zeros(num_scenarios)
for s in 1:num_scenarios
    AT_welfare[s] = sum(node_welfare[n,s] for n in AT_nodes)
    AT_welfare2[s] = sum(node_welfare2[n,s] for n in AT_nodes)
end
#France net total welfare per s 
FR_welfare = zeros(num_scenarios)
FR_welfare2 = zeros(num_scenarios)
for s in 1:num_scenarios
    FR_welfare[s] = sum(node_welfare[n,s] for n in FR_nodes)
    FR_welfare2[s] = sum(node_welfare2[n,s] for n in FR_nodes)
end

#Danish net total welfare per s
DK_welfare = zeros(num_scenarios)
DK_welfare2 = zeros(num_scenarios)
for s in 1:num_scenarios
    DK_welfare[s] = sum(node_welfare[n,s] for n in DK_nodes)
    DK_welfare2[s] = sum(node_welfare2[n,s] for n in DK_nodes)
end

#node expected net total welfare
node_exp_welfare = zeros(num_nodes)
node_exp_welfare2 = zeros(num_nodes)
for n in 1:num_nodes
    node_exp_welfare[n] = sum(prob[s]*node_welfare[n,s] for s in 1:num_scenarios)
    node_exp_welfare2[n] = sum(prob[s]*node_welfare2[n,s] for s in 1:num_scenarios)
end
#Norway expected welfare
NO_exp_welfare = sum(node_exp_welfare[n] for n in NO_nodes)
NO_exp_welfare2 = sum(node_exp_welfare2[n] for n in NO_nodes)
#Germany expected welfare
DE_exp_welfare = sum(node_exp_welfare[n] for n in DE_nodes)
DE_exp_welfare2 = sum(node_exp_welfare2[n] for n in DE_nodes)

#Norway welfare without CR
NO_private_welfare = zeros(num_scenarios)
NO_private_welfare2 = zeros(num_scenarios)
DE_private_welfare = zeros(num_scenarios)
DE_private_welfare2 = zeros(num_scenarios)
for s in 1:num_scenarios
    NO_private_welfare[s] = NO_welfare[s] - NO_total_CR[s]
    NO_private_welfare2[s] = NO_welfare2[s] - NO_total_CR2[s]
    DE_private_welfare[s] = DE_welfare[s] - DE_total_CR[s]
    DE_private_welfare2[s] = DE_welfare2[s] - DE_total_CR2[s]
end

NO_private_welfare_delta = NO_private_welfare .- NO_private_welfare2
DE_private_welfare_delta = DE_private_welfare .- DE_private_welfare2


#System welfare

#net sytstem welfare
system_welfare = zeros(num_scenarios)
system_welfare2 = zeros(num_scenarios)
for s in 1:num_scenarios
    system_welfare[s] = sum(node_welfare[n,s] for n in 1:num_nodes)
    system_welfare2[s] = sum(node_welfare2[n,s] for n in 1:num_nodes)
end
#expected net system welfare
exp_system_welfare = sum(prob[s]*system_welfare[s] for s in 1:num_scenarios)
exp_system_welfare2 = sum(prob[s]*system_welfare2[s] for s in 1:num_scenarios)


#Deltas (difference between situation with investment and without)

NO_gross_cur_welfare_delta = NO_gross_cur_welfare .- NO_gross_cur_welfare2 #per s, t
DE_gross_cur_welfare_delta = DE_gross_cur_welfare .- DE_gross_cur_welfare2 #per s, t
NO_welfare_delta = NO_welfare .- NO_welfare2 #per s (NET welfare)
DE_welfare_delta = DE_welfare .- DE_welfare2 #per s (NET welfare)
AT_welfare_delta = AT_welfare .- AT_welfare2
FR_welfare_delta = FR_welfare .- FR_welfare2
DK_welfare_delta = DK_welfare .- DK_welfare2
country_welfare_delta = [NO_welfare_delta, AT_welfare_delta, FR_welfare_delta, DE_welfare_delta, DK_welfare_delta]
NO_exp_welfare_delta = NO_exp_welfare .- NO_exp_welfare2 #(NET)
DE_exp_welfare_delta = DE_exp_welfare .- DE_exp_welfare2 #(NET)
AT_exp_welfare_delta = sum(prob[s]*AT_welfare_delta[s] for s in 1:num_scenarios)
FR_exp_welfare_delta = sum(prob[s]*FR_welfare_delta[s] for s in 1:num_scenarios)
DK_exp_welfare_delta = sum(prob[s]*DK_welfare_delta[s] for s in 1:num_scenarios)


node_exp_welfare_delta = node_exp_welfare .- node_exp_welfare2


DE_exp_gross_welfare_delta = sum(prob[s]*DE_gross_cur_welfare_delta[s,t] for s in 1:num_scenarios for t in 1:num_periods)

NO_DE_exp_welfare_delta = NO_exp_welfare_delta + DE_exp_welfare_delta 

exp_system_welfare_delta = exp_system_welfare - exp_system_welfare2

#Print some Deltas
NO_exp_welfare_delta
NO_exp_total_CS_delta
NO_combined_exp_profit_delta

DE_exp_welfare_delta
DE_exp_total_CS_delta
DE_combined_exp_profit_delta
"""So indeed we see that NO profits from exporting (PS), and DE profits from importing (CS). Note that German producers are hurt, while Norwegian consumers are not really. """


#Other interesting statistics:
four_weeks_to_year = 1.0/28*365 #scales from [per 4 weeks] to [per year]

NO_annual_exp_welfare_delta = NO_exp_welfare_delta * four_weeks_to_year
DE_annual_exp_welfare_delta = DE_exp_welfare_delta * four_weeks_to_year

line_inv_cost = x .* C_I_line
line_annual_inv_cost = line_inv_cost * four_weeks_to_year

inv_in_cur_line = x[cur_line]
inv_cost_cur_line = C_I_line[cur_line]*x[cur_line] #per four weeks
line_inv_cost_delta = line_inv_cost .- line_inv_cost2
total_line_inv_cost_delta = sum(line_inv_cost_delta)
annual_total_line_inv_cost_delta = total_line_inv_cost_delta * four_weeks_to_year


exp_CR_cur_line = line_exp_total_CR[cur_line]
annual_inv_cost_cur_line = inv_cost_cur_line*four_weeks_to_year
annual_exp_CR_cur_line = exp_CR_cur_line*four_weeks_to_year

annual_exp_system_welfare_delta = exp_system_welfare_delta * four_weeks_to_year

return_on_investment = annual_exp_system_welfare_delta/annual_total_line_inv_cost_delta

annual_NO_DE_exp_welfare_delta = NO_DE_exp_welfare_delta * four_weeks_to_year

#compute net present value of investment cost
IC = annual_inv_cost_cur_line
interest_rate = 0.04
economic_lifetime = 25
net_pres_val = 0.0
for t in 1:economic_lifetime
    global net_pres_val += (1.0 + interest_rate)^(-(t - 1)) * IC
end
net_pres_val


#Compute annual welfare parts and deltas
#CS
node_annual_exp_total_CS = node_exp_total_CS * four_weeks_to_year #CS
node_annual_exp_total_CS2 = node_exp_total_CS2 * four_weeks_to_year #CS
node_annual_exp_CS_delta = node_annual_exp_total_CS .- node_annual_exp_total_CS2
#net PS
node_annual_combined_exp_profit = node_combined_exp_profit * four_weeks_to_year #net PS
node_annual_combined_exp_profit2 = node_combined_exp_profit2 * four_weeks_to_year #net PS
node_annual_exp_net_PS_delta = node_annual_combined_exp_profit .- node_annual_combined_exp_profit2
#net CR
node_exp_net_CR = node_exp_total_CR .- node_line_inv_cost 
node_exp_net_CR2 = node_exp_total_CR2 .- node_line_inv_cost2 
node_annual_exp_net_CR = node_exp_net_CR * four_weeks_to_year
node_annual_exp_net_CR2 = node_exp_net_CR2 * four_weeks_to_year
node_annual_net_CR_delta = node_annual_exp_net_CR .- node_annual_exp_net_CR2
#total welfare
node_annual_exp_welfare_delta = node_exp_welfare_delta * four_weeks_to_year

#Store in DataFrame
node_res = DataFrame()
node_res.node = vec(nodes)
node_res.annual_exp_welfare_delta = node_annual_exp_welfare_delta
node_res.annual_exp_CS_delta = node_annual_exp_CS_delta
node_res.annual_exp_net_PS_delta = node_annual_exp_net_PS_delta
node_res.annual_exp_net_CR_delta = node_annual_net_CR_delta

#Write to CSV file
CSV.write("Results/node_results.csv", node_res)

#Also store results for the lines
line_res = DataFrame()
line_res.line = vec(lines)
line_res.x = x
line_res.annual_inv_cost = vec(line_annual_inv_cost)

#Write to CSV file
CSV.write("Results/line_results.csv", line_res)


