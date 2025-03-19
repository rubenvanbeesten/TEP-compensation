#Compute goal compensation to each country
country_welfare_delta = [NO_welfare_delta, AT_welfare_delta, FR_welfare_delta, DE_welfare_delta, DK_welfare_delta]
country_exp_welfare_delta = [NO_exp_welfare_delta, AT_exp_welfare_delta, FR_exp_welfare_delta, DE_exp_welfare_delta, DK_exp_welfare_delta]
coal_welfare_delta = NO_welfare_delta + AT_welfare_delta + FR_welfare_delta + DE_welfare_delta + DK_welfare_delta
coal_exp_welfare_delta = sum(country_exp_welfare_delta)
comp_goal = zeros(coal_size)
for i in 1:coal_size
    comp_goal[i] = (coal_exp_welfare_delta / coal_size) - country_exp_welfare_delta[i]
end


#Benchmark: no compensation
comp_no_comp = zeros(coal_size, num_scenarios)

#Define lump sum
comp_lump_sum = zeros(coal_size, num_scenarios)
for i in 1:coal_size
    for s in 1:num_scenarios
        comp_lump_sum[i,s] = comp_goal[i]
    end
end


#flow (value) preliminaries
total_flow = zeros(num_scenarios)
total_flow_value = zeros(num_scenarios)
for s in 1:num_scenarios
    total_flow[s] = sum(cur_flow[s,t] for t in 1:num_periods)
    total_flow_value[s] = sum(cur_flow[s,t] * avg_price[s,t] for t in 1:num_periods)
end
exp_total_flow = sum(prob[s]*total_flow[s] for s in 1:num_scenarios) #expected total flow through the line over all periods
exp_total_flow_value_avg = sum(prob[s]*total_flow_value[s] for s in 1:num_scenarios) #expected flow value over all perdios using avg prices
pp = function(x) #positive part
    return max(x,0)
end
np = function(x) #negative part
    return max(-x,0)
end


#Define flow-based compensation
alpha_flow = zeros(coal_size)
for i in 1:coal_size
    alpha_flow[i] = comp_goal[i]/exp_total_flow
end
comp_flow = zeros(coal_size, num_scenarios)
for i in 1:coal_size
    for s in 1:num_scenarios
        comp_flow[i,s] = alpha_flow[i] * total_flow[s]
    end
end

#Define flow value-based compensation
alpha_flow_value = zeros(coal_size)
for i in 1:coal_size
    alpha_flow_value[i] = comp_goal[i]/exp_total_flow_value_avg
end
comp_flow_value = zeros(coal_size, num_scenarios)
for i in 1:coal_size
    for s in 1:num_scenarios
        comp_flow_value[i,s] = alpha_flow_value[i] * total_flow_value[s]
    end
end

#Defin ideal model-based compensation
comp_ideal = zeros(coal_size, num_scenarios)
for s in 1:num_scenarios
    sum_country_welfare_deltas = sum(country_welfare_delta[i][s] for i in 1:coal_size)
    for i in 1:coal_size
        comp_ideal[i,s] = sum_country_welfare_deltas/coal_size - country_welfare_delta[i][s]
    end
end

comp_ideal