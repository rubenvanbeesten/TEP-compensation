
#read TEP data
xf = XLSX.readxlsx("Data/A1It6ModelData.xlsx")
#store separate sheets
Control = xf["Control"]
ProducerData = xf["ProducerData"]
LineData = xf["LineData"]
DemA = xf["DemA"]
DemB = xf["DemB"]
Prodlim = xf["Prodlim"]
Res = xf["Res"]


#STORE IN OBJECTS
nodes = LineData["O2:O19"] #list of nodes
num_nodes = length(nodes) #number of nodes
node_dict = Dict(zip(nodes, 1:num_nodes)) #dictionary for the nodes
DE_nodes = [node_dict["DE"]]
NO_nodes = 1:5
AT_nodes = [node_dict["AT"]]
FR_nodes = [node_dict["FR"]]
DK_nodes = [node_dict["DK1"], node_dict["DK2"]]
NO_DE_nodes = vcat(NO_nodes, DE_nodes)
coalition_list = ["NO", "AT", "FR", "DE", "DK"] #the coalition used in the second part of the analysis
coal_size = length(coalition_list)
slack_node = 1
lines = LineData["E2:E34"] #list of transmission lines
num_lines = length(lines) #number of transmission lines
line_NO2_DE = 7
cur_line = line_NO2_DE
generators = ProducerData["A12:A81"] #list of generators
num_generators = length(generators) #number of generators
gen_dict = Dict(zip(generators, 1:num_generators)) #dictionary for the generators
line_connect = LineData["B42:AH59"] #incidence matrix for nodes and lines
#change missing values into zeros
for n in 1:num_nodes
    for l in 1:num_lines
        if ismissing(line_connect[n,l]) 
            line_connect[n,l] = 0
        end
    end
end
abs_line_connect = abs.(line_connect) #(minuses transformed into pluses)
NO_DE_lines = zeros(num_lines) #indicates if a line is internal in the combined NO/DE zone
for l in 1:num_lines
    from = 0
    to = 0
    for n in 1:num_nodes
        if abs_line_connect[n,l] == 1
            if from == 0
                from = n
            else
                to = n
            end
        end
    end
    if from in NO_DE_nodes && to in NO_DE_nodes
        NO_DE_lines[l] = 1
    end
end
A = line_connect #new name for node/line incidence matrix
line_orig = zeros(Int8, num_lines)
line_dest = zeros(Int8, num_lines)
for l in 1:num_lines
    for n in 1:num_nodes
        if A[n,l] == 1
            line_orig[l] = n
        elseif A[n,l] == -1
            line_dest[l] = n
        end
    end
end
gen_connect_data = ProducerData["B12:B81"] #node for each generator
gen_connect = zeros(Int8,num_generators,num_nodes) #initialize incidence matrix for generators
gen_to_node = zeros(Int8,num_generators)
for g in 1:num_generators
    corresp_node = node_dict[gen_connect_data[g]]
    gen_to_node[g] = corresp_node
    gen_connect[g,corresp_node] = 1
end
num_scenarios = Control["H6"] #number of scenarios
num_periods = Control["B2"] #number of time periods
periods = 1:num_periods
winter_periods = 1:168 #ARE THESE CORRECT? SEEMS LIKE WE HAVE TWO YEARS OF DATA
spring_periods = 169:336
summer_periods = 337:504
autumn_periods = 505:672
season_periods = [winter_periods, spring_periods, summer_periods, autumn_periods] #list with seasonal periods 
seasons = ["Winter", "Spring", "Summer", "Autumn"]
num_seasons = length(seasons)
technologies = ["Solar", "Wind"] #list of renewable technologies (DIFFERENT THAN IN GAMS)
num_technologies = length(technologies) #number of renewable technologies
res_data = Res["D2:YY1081"]
#fix missing values (THIS IS AN ISSUE; BUT I'LL IGNORE IT FOR NOW)
for i in 1:size(res_data,1)
    for j in 1:size(res_data,2)
        if ismissing(res_data[i,j])
            res_data[i,j] = 0
        end
    end
end
#extract data into a four-dimensional matrix
res = zeros(num_technologies, num_nodes, num_scenarios, num_periods) #initialize matrix of renewable production amounts
for tech in 1:num_technologies
    for s in 1:num_scenarios
        for n in 1:num_nodes
            for t in 1:num_periods
                row_index = (tech - 1)*num_scenarios*num_nodes + (s-1)*num_nodes + n
                col_index = t
                res[tech,n,s,t] = res_data[row_index,col_index]
            end
        end
    end
end
pres_data = ProducerData["M85:M120"] #data for installed capacity of renewables
C_I_res_data = ProducerData["R85:R120"] #data for investment cost for renewables
pres = zeros(num_technologies,num_nodes) #init installed capacity
C_I_res = zeros(num_technologies,num_nodes) #init investment cost
for tech in 1:num_technologies
    for n in 1:num_nodes
        row = (tech - 1)*num_nodes + n
        pres[tech,n] = pres_data[row]
        C_I_res[tech,n] = C_I_res_data[row]
    end
end
prob = Control["H3:AK3"] #scenario probabilities
v = 420 #DON'T KNOW WHAT THIS IS
C_I_line = LineData["B2:B34"] #marginal investment costs for lines
l_up = LineData["J2:J34"] #initial capacity on lines
b_line = LineData["F2:F34"] #a vector of ones; not sure what the purpose ismissing
g_up = ProducerData["H85:H154"] #upper limit for production for each generator
C_gen_A = ProducerData["C3:YX7"] #parameter a for quadratic cost function for hydro generator g in time t (NOTE: ONLY FOR 5 HYDRO PRODUCERS IN NORWAY)
C_gen_B = ProducerData["C12:YX81"] #parameter b for quadratic cost function for generator g
C_I_gen = ProducerData["C85:C154"] #investment cost for each generator
dem_A_data = DemA["C2:YX541"] #data for demand A (WHAT DOES THIS MEAN?)
dem_B_data = DemB["C2:YX541"] #data for demand B (WHAT DOES THIS MEAN?)
for i in 1:size(dem_A_data,1)
    for j in 1:size(dem_A_data,2)
        if ismissing(dem_A_data[i,j])
            dem_A_data[i,j] = 0
        end
        if ismissing(dem_B_data[i,j])
            dem_B_data[i,j] = 0
        end
    end
end
dem_A = zeros(num_nodes, num_scenarios, num_periods)
dem_B = zeros(num_nodes, num_scenarios, num_periods)
for n in 1:num_nodes
    for s in 1:num_scenarios
        for t in 1:num_periods
            row_num = (s-1)*num_nodes + n
            col_num = t
            dem_A[n, s, t] = dem_A_data[row_num, col_num]
            dem_B[n, s, t] = dem_B_data[row_num, col_num]
        end
    end
end
prod_lim_data = Prodlim["D2:G2191"] #data for production limit for each generator in each scenario and season
prod_lim_gen_names = Prodlim["B2:B2191"] #names of the generators for prod lim data
prod_lim = zeros(num_generators, num_scenarios, num_seasons)
ex_num_generators = 73
for s in 1:num_scenarios
    row_start = (s-1)*ex_num_generators + 1
    row_end = row_start + ex_num_generators - 1
    for i in row_start:row_end
        cur_gen_name = prod_lim_gen_names[i]
        if cur_gen_name in keys(gen_dict)
            cur_gen_index = gen_dict[cur_gen_name]
            for seas in 1:num_seasons
                prod_lim[cur_gen_index, s, seas] = prod_lim_data[i, seas]
            end
        end
    end
end
