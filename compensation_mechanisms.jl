

#Define compensation mechanisms

#preliminaries
total_flow_value_avg = zeros(num_scenarios) #total flow value over planning horizon per scenario
for s in 1:num_scenarios
    total_flow_value_avg[s] = sum(avg_price[s,t]*cur_flow[s,t] for t in 1:num_periods)
end
exp_total_flow = sum(prob[s]*cur_flow[s,t] for s in 1:num_scenarios, t in 1:num_periods) #expected total flow through the line over all periods
exp_total_flow_value_NO2 = sum(prob[s]*NO2_price[s,t]*cur_flow[s,t] for s in 1:num_scenarios, t in 1:num_periods) #expected flow value over all periods using NO2 prices
exp_total_flow_value_DE = sum(prob[s]*DE_price[s,t]*cur_flow[s,t] for s in 1:num_scenarios, t in 1:num_periods) #expected flow value over all perdios using DE prices
exp_total_flow_value_avg = sum(prob[s]*avg_price[s,t]*cur_flow[s,t] for s in 1:num_scenarios, t in 1:num_periods) #expected flow value over all perdios using avg prices
exp_total_uncon_flow_value = sum(prob[s]*cur_line_uncongested[s,t]*DE_price[s,t]*cur_flow[s,t] for s in 1:num_scenarios, t in 1:num_periods) #expected flow value over all uncongested time periods
exp_total_con_flow_value = sum(prob[s]*(1 - cur_line_uncongested[s,t])*avg_price[s,t]*cur_flow[s,t] for s in 1:num_scenarios, t in 1:num_periods) #expected flow value over all congested time periods, at avg price
pp = function(x) #positive part
    return max(x,0)
end
np = function(x) #negative part
    return max(-x,0)
end

#no compensation
DE_comp_no_comp = zeros(num_scenarios)

#lump sump compensation
DE_comp_lump_sum = (NO_exp_welfare_delta - DE_exp_welfare_delta)/2.0 * ones(num_scenarios)
DE_comp_lump_sum_min = - DE_exp_welfare_delta * ones(num_scenarios)
DE_comp_lump_sum_max = NO_exp_welfare_delta * ones(num_scenarios)


#PPA_DE (PPA based on NO2 prices)
###PPA_DE_lb = (exp_total_flow_value_DE - DE_exp_welfare_delta)/exp_total_flow #lower bound for PPA_DE
###PPA_DE_ub = (exp_total_flow_value_DE + NO_exp_welfare_delta)/exp_total_flow #lower bound for PPA_DE

PPA_DE_ub = (- DE_exp_welfare_delta - exp_total_flow_value_DE)/(- exp_total_flow) #upper bound for PPA corresponds to lowest compensation
PPA_DE_lb = (NO_exp_welfare_delta - exp_total_flow_value_DE)/(- exp_total_flow) #lower bound for PPA corresponds to highest compensation

function compute_DE_comp_PPA_DE(PPA_DE)  #compensation to Norway resulting from PPA_DE compensation scheme (per scenario)
    comp = zeros(num_scenarios)
    for s in 1:num_scenarios
        comp[s] = sum((PPA_DE - DE_price[s,t]) * (- cur_flow[s,t]) for t in 1:num_periods) #note the minus in front of cur_flow in order to make it represent net EXPORTS
    end
    return comp
end
PPA_DE = mean([PPA_DE_lb, PPA_DE_ub]) #select some value for PPA_DE (mean value now)
DE_comp_PPA_DE = compute_DE_comp_PPA_DE(PPA_DE) #compensation to Germany from the PPA_DE
DE_comp_PPA_DE_min = compute_DE_comp_PPA_DE(PPA_DE_ub) #compensation to Germany from the PPA_DE in max case
DE_comp_PPA_DE_max = compute_DE_comp_PPA_DE(PPA_DE_lb) #compensation to Germany from the PPA_DE in min case

#PPA_NO (PPA based on NO2 prices)
PPA_NO_lb = (exp_total_flow_value_NO2 - NO_exp_welfare_delta)/exp_total_flow #lower bound for PPA_NO
PPA_NO_ub = (exp_total_flow_value_NO2 + DE_exp_welfare_delta)/exp_total_flow #lower bound for PPA_NO
function compute_NO_comp_PPA_NO(PPA_NO)  #compensation to Norway resulting from PPA_NO compensation scheme (per scenario)
    comp = zeros(num_scenarios)
    for s in 1:num_scenarios
        comp[s] = sum((PPA_NO - NO2_price[s,t]) * cur_flow[s,t] for t in 1:num_periods)
    end
    return comp
end
PPA_NO = mean([PPA_NO_lb, PPA_NO_ub]) #select some value for PPA_NO (mean value now)
DE_comp_PPA_NO = - compute_NO_comp_PPA_NO(PPA_NO) #compensation to Germany (i.e., minus comp to norway) from the PPA_NO
DE_comp_PPA_NO_min = - compute_NO_comp_PPA_NO(PPA_NO_ub) #compensation to Germany (i.e., minus comp to norway) from the PPA_NO
DE_comp_PPA_NO_max = - compute_NO_comp_PPA_NO(PPA_NO_lb) #compensation to Germany (i.e., minus comp to norway) from the PPA_NO


#Flow based (comp_DE = beta * flow)
beta_lb = - DE_exp_welfare_delta / exp_total_flow #lower bound for beta
beta_ub = NO_exp_welfare_delta / exp_total_flow #upper bond for beta
function compute_DE_comp_flow(beta)
    comp = zeros(num_scenarios)
    for s in 1:num_scenarios
        comp[s] = beta * sum(cur_flow[s,t] for t in 1:num_periods)
    end
    return comp
end
beta = mean([beta_lb, beta_ub]) #pick a value for beta
DE_comp_flow = compute_DE_comp_flow(beta)
DE_comp_flow_min = compute_DE_comp_flow(beta_lb)
DE_comp_flow_max = compute_DE_comp_flow(beta_ub)



#Flow value based (using DE prices) (comp_DE = alpha * flow_value_DE)
alpha_DE_lb = - DE_exp_welfare_delta / exp_total_flow_value_DE #lower bound for alpha_DE
alpha_DE_ub = NO_exp_welfare_delta / exp_total_flow_value_DE #upper bound for alpha_DE
function compute_DE_comp_flow_value_DE(alpha_DE)
    comp = zeros(num_scenarios)
    for s in 1:num_scenarios
        comp[s] = alpha_DE * sum(DE_price[s,t] * cur_flow[s,t] for t in 1:num_periods)
    end
    return comp
end
alpha_DE = mean([alpha_DE_lb, alpha_DE_ub]) #pick a value for alpha_DE (currently the mean value of the bounds)
DE_comp_flow_value_DE = compute_DE_comp_flow_value_DE(alpha_DE) #compensation to DE using flow value DE mechanism
DE_comp_flow_value_DE_min = compute_DE_comp_flow_value_DE(alpha_DE_lb) #compensation to DE using flow value DE mechanism
DE_comp_flow_value_DE_max = compute_DE_comp_flow_value_DE(alpha_DE_ub) #compensation to DE using flow value DE mechanism

#Flow value based (using NO2 prices) (comp_DE = alpha * flow_value_NO2)
alpha_NO_lb = - DE_exp_welfare_delta / exp_total_flow_value_NO2 #lower bound for alpha_NO
alpha_NO_ub = NO_exp_welfare_delta / exp_total_flow_value_NO2 #upper bound for alpha_NO
function compute_DE_comp_flow_value_NO(alpha_NO)
    comp = zeros(num_scenarios)
    for s in 1:num_scenarios
        comp[s] = alpha_NO * sum(NO2_price[s,t] * cur_flow[s,t] for t in 1:num_periods)
    end
    return comp
end
alpha_NO = mean([alpha_NO_lb, alpha_NO_ub]) #pick a value for alpha_NO (currently the mean value of the bounds)
DE_comp_flow_value_NO = compute_DE_comp_flow_value_NO(alpha_NO) #compensation to DE using flow value NO2 mechanism
DE_comp_flow_value_NO_min = compute_DE_comp_flow_value_NO(alpha_NO_lb) #compensation to DE using flow value NO2 mechanism
DE_comp_flow_value_NO_max = compute_DE_comp_flow_value_NO(alpha_NO_ub) #compensation to DE using flow value NO2 mechanism


#Flow value based (using avg prices) (comp_DE = alpha * flow_value_avg)
alpha_avg_lb = - DE_exp_welfare_delta / exp_total_flow_value_avg #lower bound for alpha_avg
alpha_avg_ub = NO_exp_welfare_delta / exp_total_flow_value_avg #upper bound for alpha_avg
function compute_DE_comp_flow_value_avg(alpha_avg)
    comp = zeros(num_scenarios)
    for s in 1:num_scenarios
        comp[s] = alpha_avg * sum(avg_price[s,t] * cur_flow[s,t] for t in 1:num_periods)
    end
    return comp
end
alpha_avg = mean([alpha_avg_lb, alpha_avg_ub]) #pick a value for alpha_avg (currently the mean value of the bounds)
DE_comp_flow_value_avg = compute_DE_comp_flow_value_avg(alpha_avg) #compensation to DE using flow value avg mechanism
DE_comp_flow_value_avg_min = compute_DE_comp_flow_value_avg(alpha_avg_lb) #compensation to DE using flow value avg mechanism
DE_comp_flow_value_avg_max = compute_DE_comp_flow_value_avg(alpha_avg_ub) #compensation to DE using flow value avg mechanism


#uncongested flow value based (using any price since they are the same) (comp_DE = alpha_uncon * flow_value_uncon)
alpha_uncon_lb = - DE_exp_welfare_delta / exp_total_uncon_flow_value #lower bound for alpha_uncon
alpha_uncon_ub = NO_exp_welfare_delta / exp_total_uncon_flow_value #upper bound for alpha_uncon
function compute_DE_comp_uncon_flow_value(alpha_uncon)
    comp = zeros(num_scenarios)
    for s in 1:num_scenarios
        comp[s] = alpha_uncon * sum(cur_line_uncongested[s,t] * DE_price[s,t] * cur_flow[s,t] for t in 1:num_periods)
    end 
    return comp
end
alpha_uncon = mean([alpha_uncon_lb, alpha_uncon_ub]) #pick a value for alpha_uncon (currently the mean value of the bounds)
DE_comp_uncon_flow_value = compute_DE_comp_uncon_flow_value(alpha_uncon) #compensation to DE using uncon flow value mechanism
DE_comp_uncon_flow_value_min = compute_DE_comp_uncon_flow_value(alpha_uncon_lb) #compensation to DE using uncon flow value mechanism
DE_comp_uncon_flow_value_max = compute_DE_comp_uncon_flow_value(alpha_uncon_ub) #compensation to DE using uncon flow value mechanism


#congested flow value based (using avg price) (comp_DE = alpha_con * flow_value_con)
alpha_con_lb = - DE_exp_welfare_delta / exp_total_con_flow_value #lower bound for alpha_con
alpha_con_ub = NO_exp_welfare_delta / exp_total_con_flow_value #upper bound for alpha_con
function compute_DE_comp_con_flow_value(alpha_con)
    comp = zeros(num_scenarios)
    for s in 1:num_scenarios
        comp[s] = alpha_con * sum((1 - cur_line_uncongested[s,t]) * avg_price[s,t] * cur_flow[s,t] for t in 1:num_periods)
    end 
    return comp
end
alpha_con = mean([alpha_con_lb, alpha_con_ub]) #pick a value for alpha_con (currently the mean value of the bounds)
DE_comp_con_flow_value = compute_DE_comp_con_flow_value(alpha_con) #compensation to DE using con flow value mechanism
DE_comp_con_flow_value_min = compute_DE_comp_con_flow_value(alpha_con_lb) #compensation to DE using con flow value mechanism
DE_comp_con_flow_value_max = compute_DE_comp_con_flow_value(alpha_con_ub) #compensation to DE using con flow value mechanism


#Flow value halved (0.5 lump sum + 0.5 flow value)
DE_comp_flow_value_halved = 0.5 * DE_comp_lump_sum + 0.5 * DE_comp_flow_value_avg 

#Flow value doubled (-1 lump sum + 2 flow value)
DE_comp_flow_value_doubled = -1.0 * DE_comp_lump_sum + 2.0 * DE_comp_flow_value_avg 

#Flow value tripled (-2 lump sum + 3 flow value)
DE_comp_flow_value_tripled = -2.0 * DE_comp_lump_sum + 3.0 * DE_comp_flow_value_avg 

#Flow value quadrupled (-3 lump sum + 4 flow value)
DE_comp_flow_value_quadrupled = -3.0 * DE_comp_lump_sum + 4.0 * DE_comp_flow_value_avg 

#Flow value quadratic (basic form: C = alpha * flow_value^2)
exp_flow_value_squared = sum(prob[s] * total_flow_value_avg[s]^2 for s in 1:num_scenarios)
alpha_quad = DE_comp_lump_sum[1]/exp_flow_value_squared
DE_comp_flow_value_squared = alpha_quad * total_flow_value_avg.^2

#Flow value quadratic (adjusted form; with base at 4e7: C = alpha * (flow_value - 4e7)^2)
exp_flow_value_squared_adj = sum(prob[s] * (total_flow_value_avg[s] - 4.0e7)^2 for s in 1:num_scenarios)
alpha_quad_adj = DE_comp_lump_sum[1]/exp_flow_value_squared_adj
DE_comp_flow_value_squared_adj = alpha_quad_adj * (total_flow_value_avg .- 4.0e7).^2

#Model-based compensation (ideal mechanism)
DE_comp_ideal = (NO_welfare_delta .- DE_welfare_delta)/2.0



#plotting
make_plots = false
if make_plots
    #load package
    using Plots

    #set plotting environment
    gr()
    #DE welfare delta vs NO welfare delta
    plot(DE_welfare_delta, NO_welfare_delta, seriestype=:scatter, xlabel="DE welfare delta", ylabel="NO welfare delta", xlims=(-2.0e7, 2.0e7), ylims=(-2.0e7, 4.0e7), legend=false)
    plot!([-2e7, 2e7], [0,0], color=:black, linestyle=:dot) #add x axis
    plot!([0,0], [-2e7, 4e7], color=:black, linestyle=:dot) #add y axis
    plot!([-2e7,2e7], [2e7, -2e7], color=:red, linestyle=:dash) #add 45 degree line

    #total flow value vs DE welfare delta
    plot(total_flow_value_avg, DE_welfare_delta, seriestype=:scatter, xlabel="flow value", ylabel="DE welfare delta", xlims=(2.5e7, 9.5e7), ylims=(-2.0e7, 4.0e7), legend=false)
    #total flow value vs NO welfare delta
    plot(total_flow_value_avg, NO_welfare_delta, seriestype=:scatter, xlabel="flow value", ylabel="NO welfare delta", xlims=(2.5e7, 9.5e7), ylims=(-2.0e7, 4.0e7), legend=false)
    #total flow value vs NO/DE welfare delta
    plot(total_flow_value_avg, [NO_welfare_delta, DE_welfare_delta], seriestype=:scatter, seriescolor=[:blue :red], label=["NO" "DE"], markershape=[:circle :x], xlabel="flow value", ylabel="NO welfare delta", xlims=(2.5e7, 9.5e7), ylims=(-2.0e7, 4.0e7), legend=:topleft)
end


