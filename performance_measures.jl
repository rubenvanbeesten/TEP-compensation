

#compute statistics
compute_CVaR = function(list, alpha) #compute CVaR from a list of equally likely numbers
    x = sort(list)
    n = length(x)
    an = alpha*n
    an_c = Int64(ceil(an))
    sum = 0.0
    for i in (an_c + 1):n
        sum += x[i]
    end
    if an > 0.0
        sum += (an_c - an) * x[an_c]
    end
    return 1.0/(n * (1.0 - alpha)) * sum
end


#list the mechanisms
mechanisms = ["no_compensation", "lump_sum", "PPA_DE", "PPA_NO", "flow", "flow_value_DE", "flow_value_NO", "flow_value_avg", "uncon_flow_value", "con_flow_value", "flow_value_halved", "flow_value_doubled", "flow_value_tripled", "flow_value_quadrupled", "flow_value_squared", "flow_value_squared_adj", "ideal"]
#list the compensation vectors
DE_comp_list = [DE_comp_no_comp, DE_comp_lump_sum, DE_comp_PPA_DE, DE_comp_PPA_NO, DE_comp_flow, DE_comp_flow_value_NO, DE_comp_flow_value_DE, DE_comp_flow_value_avg, DE_comp_uncon_flow_value, DE_comp_con_flow_value, DE_comp_flow_value_halved, DE_comp_flow_value_doubled, DE_comp_flow_value_tripled, DE_comp_flow_value_quadrupled, DE_comp_flow_value_squared, DE_comp_flow_value_squared_adj, DE_comp_ideal]
#initialize statistics
avg_DE_comp = zeros(length(mechanisms))
avg_DE_net_welfare_delta = zeros(length(mechanisms))
avg_NO_net_welfare_delta = zeros(length(mechanisms))
std_DE_comp = zeros(length(mechanisms))
std_DE_net_welfare_delta = zeros(length(mechanisms))
std_NO_net_welfare_delta = zeros(length(mechanisms))
std_DE_net_welfare = zeros(length(mechanisms))
std_NO_net_welfare = zeros(length(mechanisms))
prob_DE_loss = zeros(length(mechanisms))
prob_NO_loss = zeros(length(mechanisms))
avg_DE_loss = zeros(length(mechanisms))
avg_NO_loss = zeros(length(mechanisms))
CVaR_90_DE_loss = zeros(length(mechanisms))
CVaR_90_NO_loss = zeros(length(mechanisms))
CVaR_80_DE_loss = zeros(length(mechanisms))
CVaR_80_NO_loss = zeros(length(mechanisms))
for m in 1:length(mechanisms)
    #initialize
    DE_comp = DE_comp_list[m]
    DE_net_welfare_delta = DE_welfare_delta .+ DE_comp
    NO_net_welfare_delta = NO_welfare_delta .- DE_comp
    DE_net_welfare = DE_welfare .+ DE_comp
    NO_net_welfare = NO_welfare .- DE_comp
    DE_loss = map(np, DE_net_welfare_delta)
    NO_loss = map(np, NO_net_welfare_delta)
    #compute statistics
    avg_DE_comp[m] = mean(DE_comp)
    std_DE_comp[m] = std(DE_comp)
    avg_DE_net_welfare_delta[m] = mean(DE_net_welfare_delta)
    avg_NO_net_welfare_delta[m] = mean(NO_net_welfare_delta)
    std_DE_net_welfare_delta[m] = std(DE_net_welfare_delta)
    std_NO_net_welfare_delta[m] = std(NO_net_welfare_delta)
    std_DE_net_welfare[m] = std(DE_net_welfare)
    std_NO_net_welfare[m] = std(NO_net_welfare)
    prob_DE_loss[m] = sum(prob[s] * (DE_loss[s] > 0.0) for s in 1:num_scenarios)
    prob_NO_loss[m] = sum(prob[s] * (NO_loss[s] > 0.0) for s in 1:num_scenarios)
    avg_DE_loss[m] = mean(DE_loss)
    avg_NO_loss[m] = mean(NO_loss)
    CVaR_90_DE_loss[m] = compute_CVaR(DE_loss, 0.90)
    CVaR_90_NO_loss[m] = compute_CVaR(NO_loss, 0.90)
    CVaR_80_DE_loss[m] = compute_CVaR(DE_loss, 0.80)
    CVaR_80_NO_loss[m] = compute_CVaR(NO_loss, 0.80)
end
std([1,2,3,4])
#write to dataframe
comp = DataFrame()
comp.mechanism = mechanisms
comp.avg_DE_comp = avg_DE_comp
comp.std_DE_comp = std_DE_comp
comp.avg_DE_net_welfare_delta = avg_DE_net_welfare_delta
comp.avg_NO_net_welfare_delta = avg_NO_net_welfare_delta
comp.std_DE_net_welfare_delta = std_DE_net_welfare_delta
comp.std_NO_net_welfare_delta = std_NO_net_welfare_delta
comp.std_DE_net_welfare = std_DE_net_welfare
comp.std_NO_net_welfare = std_NO_net_welfare
comp.prob_DE_loss = prob_DE_loss
comp.prob_NO_loss = prob_NO_loss
comp.avg_DE_loss = avg_DE_loss
comp.avg_NO_loss = avg_NO_loss
comp.CVaR_90_DE_loss = CVaR_90_DE_loss
comp.CVaR_90_NO_loss = CVaR_90_NO_loss
comp.CVaR_80_DE_loss = CVaR_80_DE_loss
comp.CVaR_80_NO_loss = CVaR_80_NO_loss

#write results to CSV file
file_name = "Results/statistics_out_main.csv"
CSV.write(file_name, comp)

#Output data for making plots
plout = DataFrame()
plout.DE_welfare_delta = DE_welfare_delta
plout.NO_welfare_delta = NO_welfare_delta
plout.DE_comp_no_comp = DE_comp_no_comp
plout.DE_comp_lump_sum = DE_comp_lump_sum
plout.DE_comp_PPA_DE = DE_comp_PPA_DE
plout.DE_comp_PPA_NO = DE_comp_PPA_NO
plout.DE_comp_flow = DE_comp_flow
plout.DE_comp_flow_value_NO = DE_comp_flow_value_NO
plout.DE_comp_flow_value_DE = DE_comp_flow_value_DE
plout.DE_comp_flow_value_avg = DE_comp_flow_value_avg
plout.DE_comp_uncon_flow_value = DE_comp_uncon_flow_value
plout.DE_comp_con_flow_value = DE_comp_con_flow_value
plout.DE_comp_ideal = DE_comp_ideal

#write results to CSV file
file_name = "Results/plotting_out_main.csv"
CSV.write(file_name, plout)







#Deprecated: min/max/fair compensation_levels

"""
compensation_levels = ["fair", "min", "max"]
for level in compensation_levels
    mechanisms = ["no_compensation", "lump_sum", "PPA_DE", "PPA_NO", "flow", "flow_value_DE", "flow_value_NO", "flow_value_avg", "uncon_flow_value", "con_flow_value"]
    DE_comp_list = []
    if level == "fair"
        DE_comp_list = [DE_comp_no_comp, DE_comp_lump_sum, DE_comp_PPA_DE, DE_comp_PPA_NO, DE_comp_flow, DE_comp_flow_value_NO, DE_comp_flow_value_DE, DE_comp_flow_value_avg, DE_comp_uncon_flow_value, DE_comp_con_flow_value, DE_comp_flow_value_halved, DE_comp_flow_value_doubled, DE_comp_flow_value_doubled]
    elseif level == "min"
        DE_comp_list = [DE_comp_no_comp, DE_comp_lump_sum_min, DE_comp_PPA_DE_min, DE_comp_PPA_NO_min, DE_comp_flow_min, DE_comp_flow_value_NO_min, DE_comp_flow_value_DE_min, DE_comp_flow_value_avg_min, DE_comp_uncon_flow_value_min, DE_comp_con_flow_value_min, DE_comp_flow_value_halved_min, DE_comp_flow_value_doubled_min]
    elseif level == "max"
        DE_comp_list = [DE_comp_no_comp, DE_comp_lump_sum_max, DE_comp_PPA_DE_max, DE_comp_PPA_NO_max, DE_comp_flow_max, DE_comp_flow_value_NO_max, DE_comp_flow_value_DE_max, DE_comp_flow_value_avg_max, DE_comp_uncon_flow_value_max, DE_comp_con_flow_value_max, DE_comp_flow_value_halved_max, DE_comp_flow_value_doubled_max]
    end
    avg_DE_comp = zeros(length(mechanisms))
    avg_DE_net_welfare_delta = zeros(length(mechanisms))
    avg_NO_net_welfare_delta = zeros(length(mechanisms))
    std_DE_comp = zeros(length(mechanisms))
    std_DE_net_welfare_delta = zeros(length(mechanisms))
    std_NO_net_welfare_delta = zeros(length(mechanisms))
    std_DE_net_welfare = zeros(length(mechanisms))
    std_NO_net_welfare = zeros(length(mechanisms))
    prob_DE_loss = zeros(length(mechanisms))
    prob_NO_loss = zeros(length(mechanisms))
    avg_DE_loss = zeros(length(mechanisms))
    avg_NO_loss = zeros(length(mechanisms))
    CVaR_90_DE_loss = zeros(length(mechanisms))
    CVaR_90_NO_loss = zeros(length(mechanisms))
    CVaR_80_DE_loss = zeros(length(mechanisms))
    CVaR_80_NO_loss = zeros(length(mechanisms))
    for m in 1:length(mechanisms)
        #initialize
        DE_comp = DE_comp_list[m]
        DE_net_welfare_delta = DE_welfare_delta .+ DE_comp
        NO_net_welfare_delta = NO_welfare_delta .- DE_comp
        DE_net_welfare = DE_welfare .+ DE_comp
        NO_net_welfare = NO_welfare .- DE_comp
        DE_loss = map(np, DE_net_welfare_delta)
        NO_loss = map(np, NO_net_welfare_delta)
        #compute statistics
        avg_DE_comp[m] = mean(DE_comp)
        std_DE_comp[m] = std(DE_comp)
        avg_DE_net_welfare_delta[m] = mean(DE_net_welfare_delta)
        avg_NO_net_welfare_delta[m] = mean(NO_net_welfare_delta)
        std_DE_net_welfare_delta[m] = std(DE_net_welfare_delta)
        std_NO_net_welfare_delta[m] = std(NO_net_welfare_delta)
        std_DE_net_welfare[m] = std(DE_net_welfare)
        std_NO_net_welfare[m] = std(NO_net_welfare)
        prob_DE_loss[m] = sum(prob[s] * (DE_loss[s] > 0.0) for s in 1:num_scenarios)
        prob_NO_loss[m] = sum(prob[s] * (NO_loss[s] > 0.0) for s in 1:num_scenarios)
        avg_DE_loss[m] = mean(DE_loss)
        avg_NO_loss[m] = mean(NO_loss)
        CVaR_90_DE_loss[m] = compute_CVaR(DE_loss, 0.90)
        CVaR_90_NO_loss[m] = compute_CVaR(NO_loss, 0.90)
        CVaR_80_DE_loss[m] = compute_CVaR(DE_loss, 0.80)
        CVaR_80_NO_loss[m] = compute_CVaR(NO_loss, 0.80)
    end
    std([1,2,3,4])
    #write to dataframe
    comp = DataFrame()
    comp.mechanism = mechanisms
    comp.avg_DE_comp = avg_DE_comp
    comp.std_DE_comp = std_DE_comp
    comp.avg_DE_net_welfare_delta = avg_DE_net_welfare_delta
    comp.avg_NO_net_welfare_delta = avg_NO_net_welfare_delta
    comp.std_DE_net_welfare_delta = std_DE_net_welfare_delta
    comp.std_NO_net_welfare_delta = std_NO_net_welfare_delta
    comp.std_DE_net_welfare = std_DE_net_welfare
    comp.std_NO_net_welfare = std_NO_net_welfare
    comp.prob_DE_loss = prob_DE_loss
    comp.prob_NO_loss = prob_NO_loss
    comp.avg_DE_loss = avg_DE_loss
    comp.avg_NO_loss = avg_NO_loss
    comp.CVaR_90_DE_loss = CVaR_90_DE_loss
    comp.CVaR_90_NO_loss = CVaR_90_NO_loss
    comp.CVaR_80_DE_loss = CVaR_80_DE_loss
    comp.CVaR_80_NO_loss = CVaR_80_NO_loss

    #write results to CSV file
    file_name = "Results/statistics_out_"
    file_name = file_name * level * ".csv"
    CSV.write(file_name, comp)

    comp
    

    #Output data for making plots
    plout = DataFrame()
    if level == "fair"
        plout.DE_welfare_delta = DE_welfare_delta
        plout.NO_welfare_delta = NO_welfare_delta
        plout.DE_comp_no_comp = DE_comp_no_comp
        plout.DE_comp_lump_sum = DE_comp_lump_sum
        plout.DE_comp_PPA_DE = DE_comp_PPA_DE
        plout.DE_comp_PPA_NO = DE_comp_PPA_NO
        plout.DE_comp_flow = DE_comp_flow
        plout.DE_comp_flow_value_NO = DE_comp_flow_value_NO
        plout.DE_comp_flow_value_DE = DE_comp_flow_value_DE
        plout.DE_comp_flow_value_avg = DE_comp_flow_value_avg
        plout.DE_comp_uncon_flow_value = DE_comp_uncon_flow_value
        plout.DE_comp_con_flow_value = DE_comp_con_flow_value
    elseif level == "min"
        plout.DE_welfare_delta = DE_welfare_delta
        plout.NO_welfare_delta = NO_welfare_delta
        plout.DE_comp_no_comp = DE_comp_no_comp
        plout.DE_comp_lump_sum = DE_comp_lump_sum_min
        plout.DE_comp_PPA_DE = DE_comp_PPA_DE_min
        plout.DE_comp_PPA_NO = DE_comp_PPA_NO_min
        plout.DE_comp_flow = DE_comp_flow_min
        plout.DE_comp_flow_value_NO = DE_comp_flow_value_NO_min
        plout.DE_comp_flow_value_DE = DE_comp_flow_value_DE_min
        plout.DE_comp_flow_value_avg = DE_comp_flow_value_avg_min
        plout.DE_comp_uncon_flow_value = DE_comp_uncon_flow_value_min
        plout.DE_comp_con_flow_value = DE_comp_con_flow_value_min
    elseif level == "max"
        plout.DE_welfare_delta = DE_welfare_delta
        plout.NO_welfare_delta = NO_welfare_delta
        plout.DE_comp_no_comp = DE_comp_no_comp
        plout.DE_comp_lump_sum = DE_comp_lump_sum_max
        plout.DE_comp_PPA_DE = DE_comp_PPA_DE_max
        plout.DE_comp_PPA_NO = DE_comp_PPA_NO_max
        plout.DE_comp_flow = DE_comp_flow_max
        plout.DE_comp_flow_value_NO = DE_comp_flow_value_NO_max
        plout.DE_comp_flow_value_DE = DE_comp_flow_value_DE_max
        plout.DE_comp_flow_value_avg = DE_comp_flow_value_avg_max
        plout.DE_comp_uncon_flow_value = DE_comp_uncon_flow_value_max
        plout.DE_comp_con_flow_value = DE_comp_con_flow_value_max
    end
    #write results to CSV file
    file_name = "Results/plotting_out_"
    file_name = file_name * level * ".csv"
    CSV.write(file_name, plout)

end
"""

"End of performance_measures.jl"