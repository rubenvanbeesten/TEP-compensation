"""
Making plots based on the TEP output
"""

import os
import pandas as pd
from pandas import ExcelWriter
from pandas import ExcelFile
import numpy as np
import matplotlib.pyplot as plt

os.chdir("//home.ansatt.ntnu.no/egbertrv/Documents/Research/Transmission expansion/Code/TEP_Julia/Results")



def plot_welfare_sector(scale=2):
    #read data
    node_data = pd.read_excel("Processed results/New/All NO DE/nodes_all_NO_DE.xlsx", sheet_name="Per country")
    
    #process data
    country_names = node_data["node"]
    delta_CS = node_data["delta(CS)"]
    delta_PS = node_data["delta(net PS)"]
    delta_CR = node_data["delta(net CR)"]
    delta_TW = node_data["delta(TW)"]
    num_countries = len(country_names)
    num_variables = 4
    
    #compute totals over all countries (in billions of euros)
    total_delta_CS = np.multiply(0.000000001, sum(delta_CS))
    total_delta_PS = np.multiply(0.000000001, sum(delta_PS))
    total_delta_CR = np.multiply(0.000000001, sum(delta_CR))
    total_delta_TW = np.multiply(0.000000001, sum(delta_TW))
    
    bars = [total_delta_CS, total_delta_PS, total_delta_CR, total_delta_TW]
     
    # Set position of bar on X axis
    r = np.arange(num_variables)
    
    #set colors
    colors = ["green", "darkred", "violet", "navy"]
    variable_names = ["CS", "net PS", "net CR", "TW"]
    
    barWidth = 0.6
    
    plt.bar(r, bars, width=barWidth, color=colors)
    
    plt.xticks(r, variable_names)
    plt.xlabel('measure', fontweight='bold')
    plt.ylabel('annual welfare effect (bln euros)', fontweight="bold")
    
    plt.savefig('Plots/plot_welfare_sector.png')
    
    plt.show()




#make a plot of the welfare change per country 
def plot_welfare_country(scale=2):
    #read data
    node_data = pd.read_excel("Processed results/New/All NO DE/nodes_all_NO_DE.xlsx", sheet_name="Per country")
    
    #process data
    country_names = node_data["node"]
    delta_TW = node_data["delta(TW)"]
    num_countries = len(country_names)
        
    #rescale to millions of euros
    delta_TW = np.multiply(0.000001, delta_TW)
    
    #plot size
    screen_ratio = (4,3)
    plt.rcParams["figure.figsize"] = np.multiply(scale,screen_ratio)
    
    #make the plot
    r = np.arange(num_countries)
    plt.bar(r, delta_TW, width=0.7, color="navy")
     
    # Add xticks on the middle of the group bars
    plt.xticks(r, country_names)
    plt.xlabel('country', fontweight='bold')
    plt.ylabel('annual welfare effect (mln euros)', fontweight="bold")
    
    #save    
    plt.savefig('Plots/plot_welfare_country.png')
    
    #Show graphic
    plt.show()


#make a plot of the welfare effect per country per sector
def plot_welfare_country_sector(scale=2):
    #read data
    node_data = pd.read_excel("Processed results/New/All NO DE/nodes_all_NO_DE.xlsx", sheet_name="Per country")
    
    #process data
    country_names = node_data["node"]
    delta_CS = node_data["delta(CS)"]
    delta_PS = node_data["delta(net PS)"]
    delta_CR = node_data["delta(net CR)"]
    delta_TW = node_data["delta(TW)"]
    num_countries = len(country_names)
    num_variables = 4

    #plot size settings
    screen_ratio = (4,3)
    plt.rcParams["figure.figsize"] = np.multiply(scale,screen_ratio)
    
    # set width of bars
    barWidth = 0.18
     
    # set heights of bars
    bars = []
    
    bars.append(delta_CS)
    bars.append(delta_PS)
    bars.append(delta_CR)
    bars.append(delta_TW)
    
    #rescale to billions of euros
    bars = np.multiply(0.000000001, bars)
     
    # Set position of bar on X axis
    r_base = np.arange(num_countries)
    r = []
    for j in np.arange(num_variables):
        r.append(r_base + j*barWidth)
    
    #set colors
    colors = ["green", "darkred", "violet", "navy"]
    labels = ["CS", "net PS", "net CR", "TW"]
    
    # Make the plot
    for j in np.arange(num_variables):
        plt.bar(r[j], bars[j], color=colors[j], width=barWidth, label=labels[j] )
        
    # Add xticks on the middle of the group bars
    plt.xticks([r + 2*barWidth for r in r_base], country_names)
    plt.xlabel('country', fontweight='bold')
    plt.ylabel('annual welfare effect (bln euros)', fontweight="bold")
    
    # Create legend & Show graphic
    plt.legend()
   
    #save    
    plt.savefig('Plots/plot_welfare_country_sector.png')
    
    plt.show()


def boxplot_welfare_mechanisms(scale=2):
    
    #read excel file
    data_comp = pd.read_excel("Processed results/New/All NO DE/plots_all_NO_DE_fair.xlsx", sheet_name="compensation NO -> DE")
    data_DE = pd.read_excel("Processed results/New/All NO DE/plots_all_NO_DE_fair.xlsx", sheet_name="net welfare delta DE")
    data_NO = pd.read_excel("Processed results/New/All NO DE/plots_all_NO_DE_fair.xlsx", sheet_name="net welfare delta NO")
    
    for sheet in ["comp", "DE", "NO"]:
        
        #choose dataset
        data = []
        if sheet == "comp":
            data = data_comp    
        elif sheet == "DE":
            data = data_DE
        elif sheet == "NO":
            data = data_NO
        
            
        #scaling factor
        four_weeks_to_year = 1.0/28*365
        
        #extract data
        no_comp = np.multiply(0.000001 * four_weeks_to_year, data["no_comp"])
        lump_sum = np.multiply(0.000001 * four_weeks_to_year, data["lump_sum"])
        PPA_DE = np.multiply(0.000001 * four_weeks_to_year, data["PPA_DE"])
        PPA_NO = np.multiply(0.000001 * four_weeks_to_year, data["PPA_NO"])
        flow = np.multiply(0.000001 * four_weeks_to_year, data["flow"])
        flow_value = np.multiply(0.000001 * four_weeks_to_year, data["flow_value_avg"])
        ideal = np.multiply(0.000001 * four_weeks_to_year, data["ideal"])
            
        #put relevant data into vectors
        data_vec =  [no_comp, lump_sum, PPA_DE, PPA_NO, flow, flow_value, ideal]
        mech_names = ["no comp", "lump sum", "PPA_DE", "PPA_NO", "flow", "flow value", "ideal"]
        
                    
        #size settings
        screen_ratio = (4,3)
        plt.rcParams["figure.figsize"] = np.multiply(scale,screen_ratio)
       
        # Creating figure/axis
        fig, ax = plt.subplots()
        
        #creating boxplot
        ax.boxplot(data_vec, meanline=True, showmeans=True, patch_artist=True)
        plt.xticks(np.arange(len(mech_names)) + 1, mech_names)
        
        #save plot
        filename = "Plots/boxplot_" + sheet + ".png"               
        plt.savefig(filename)
        
        #show plot
        plt.show()
     
    

#run the functions (i.e., make the plots) and save
#plot_welfare_sector()
#plot_welfare_country()
#plot_welfare_country_sector()
boxplot_welfare_mechanisms()



















