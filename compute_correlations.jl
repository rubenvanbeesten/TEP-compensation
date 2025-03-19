#preliminaries 
cur_line_CR = line_CR[cur_line,:,:] #congestion rent earned on cur line
cur_flow = f[cur_line,:,:] # flow on cur line
avg_price = 0.5 * NO2_price .+ 0.5* DE_price #avg price on each end of the line
cur_flow_value_avg = cur_flow .* avg_price

cur_line_total_CR = zeros(num_scenarios)
cur_total_flow = zeros(num_scenarios)
cur_total_flow_value_avg = zeros(num_scenarios)
for s in 1:num_scenarios
    cur_line_total_CR[s] = sum(line_CR[cur_line,s,t] for t in 1:num_periods)
    cur_total_flow[s] = sum(cur_flow[s,t] for t in 1:num_periods)
    cur_total_flow_value_avg[s] = sum(cur_flow_value_avg[s,t] for t in 1:num_periods)
end
 

#compute correlations
cor_welfare_delta_vs_CR = zeros(coal_size)
cor_welfare_delta_vs_flow = zeros(coal_size)
cor_welfare_delta_vs_flow_value_avg = zeros(coal_size)
for i in 1:coal_size
    cor_welfare_delta_vs_CR[i] = cor(country_welfare_delta[i], cur_line_total_CR)
    cor_welfare_delta_vs_flow[i] = cor(country_welfare_delta[i], cur_total_flow)
    cor_welfare_delta_vs_flow_value_avg[i] = cor(country_welfare_delta[i], cur_total_flow_value_avg)
end
#store in data frame
corr = DataFrame() #dataframe containing correlations between welfare delta vs. various variables
corr.country = coalition_list
corr.CR = cor_welfare_delta_vs_CR
corr.flow = cor_welfare_delta_vs_flow
corr.flow_value_avg = cor_welfare_delta_vs_flow_value_avg


#print to CSV file
CSV.write("Results/correlations.csv", corr)




#Correlations between welfare deltas of coalition countries:
coalition_welfare_deltas = [NO_welfare_delta, AT_welfare_delta, FR_welfare_delta, DE_welfare_delta, DK_welfare_delta] #same order as coalition_list = ["NO", "AT", "FR", "DE", "DK"]
coalition_correlations = zeros(length(coalition_list), length(coalition_list))
for i in 1:length(coalition_list)
    for j in 1:length(coalition_list)
        coalition_correlations[i,j] = cor(coalition_welfare_deltas[i], coalition_welfare_deltas[j])
    end
end

coalition_corr = DataFrame()
coalition_corr.coalition = coalition_list
coalition_corr.NO = coalition_correlations[1,:]
coalition_corr.AT = coalition_correlations[2,:]
coalition_corr.FR = coalition_correlations[3,:]
coalition_corr.DE = coalition_correlations[4,:]
coalition_corr.DK = coalition_correlations[5,:]

CSV.write("Results/coalition_correlations.csv", coalition_corr)



#Price correlations
price_diff = DE_price .- NO2_price

cor_NO_welfare_delta_NO2_price = cor(vec(NO_gross_cur_welfare_delta), vec(NO2_price))
cor_DE_welfare_delta_NO2_price = cor(vec(DE_gross_cur_welfare_delta), vec(NO2_price))
cor_NO_welfare_delta_DE_price = cor(vec(NO_gross_cur_welfare_delta), vec(DE_price))
cor_DE_welfare_delta_DE_price = cor(vec(DE_gross_cur_welfare_delta), vec(DE_price))
#result: stronger correlations with NO2 prices

cor_NO_welfare_delta_price_diff = cor(vec(NO_gross_cur_welfare_delta), vec(price_diff))
cor_DE_welfare_delta_price_diff = cor(vec(DE_gross_cur_welfare_delta), vec(price_diff))
#both countries profit more if there is a larger price difference
#we need a mechanism that pays higher compensations when price difference is lower => PPA_NO

price_corr = DataFrame()
price_corr.variable = ["NO_cur_welfare_delta", "DE_cur_welfare_delta"]
price_corr.NO2_price = [cor_NO_welfare_delta_NO2_price, cor_DE_welfare_delta_NO2_price]
price_corr.DE_price = [cor_NO_welfare_delta_DE_price, cor_DE_welfare_delta_DE_price]
price_corr.price_diff = [cor_NO_welfare_delta_price_diff, cor_DE_welfare_delta_price_diff]

CSV.write("Results/price_correlations.csv", price_corr)


