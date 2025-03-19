#function to compute CVaR
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

#list mechanisms
mechanisms = ["no_comp", "lump_sum", "flow", "flow_value_avg", "ideal"]



#compute statistics (general order of indices: m (mechanism), i (country), s (scenario) )
comp = [comp_no_comp, comp_lump_sum, comp_flow, comp_flow_value, comp_ideal]
avg_comp = zeros(length(mechanisms), coal_size)
net_welfare_delta = zeros(length(mechanisms), coal_size, num_scenarios)
country_loss = zeros(length(mechanisms), coal_size, num_scenarios)
avg_net_welfare_delta = zeros(length(mechanisms), coal_size)
std_comp = zeros(length(mechanisms), coal_size)
std_net_welfare_delta = zeros(length(mechanisms), coal_size)
prob_loss = zeros(length(mechanisms), coal_size)
avg_loss = zeros(length(mechanisms), coal_size)
CVaR_80_loss = zeros(length(mechanisms), coal_size)
for m in 1:length(mechanisms)
    for i in 1:coal_size
        for s in 1:num_scenarios
            net_welfare_delta[m,i,s] = country_welfare_delta[i][s] + comp[m][i,s]
            country_loss[m,i,s] = np(net_welfare_delta[m,i,s])
        end
        avg_comp[m,i] = sum(prob[s]*comp[m][i,s] for s in 1:num_scenarios)
        avg_net_welfare_delta[m,i] = sum(prob[s]*net_welfare_delta[m,i,s] for s in 1:num_scenarios)
        std_comp[m,i] = std(comp[m][i,:])
        std_net_welfare_delta[m,i] = std(net_welfare_delta[m,i,:])
        prob_loss[m,i] = sum(prob[s] * (country_loss[m,i,s] > 0.0) for s in 1:num_scenarios)
        avg_loss[m,i] = sum(prob[s] * country_loss[m,i,s] for s in 1:num_scenarios)
        CVaR_80_loss[m,i] = compute_CVaR(country_loss[m,i,:], 0.80)
    end
end

#write to dataframe and CSV file
file_name_base = "Results/statistics_coal_"
for i in 1:coal_size
    #make data frame and fill it
    comp_coal = DataFrame()
    comp_coal.mechanism = mechanisms
    comp_coal.avg_comp = avg_comp[:,i]
    comp_coal.avg_net_welfare_delta = avg_net_welfare_delta[:,i]
    comp_coal.std_comp = std_comp[:,i]
    comp_coal.std_net_welfare_delta = std_net_welfare_delta[:,i]
    comp_coal.prob_loss = prob_loss[:,i]
    comp_coal.avg_loss = avg_loss[:,i]
    comp_coal.CVaR_80_loss = CVaR_80_loss[:,i]

    #save in CSV file
    file_name = file_name_base * coalition_list[i] * ".csv"
    CSV.write(file_name, comp_coal)
end



